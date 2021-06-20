import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_area_network/bloc/app_bloc.dart';
import 'package:local_area_network/bloc/clip_bloc.dart';
import 'package:local_area_network/bloc/device_bloc.dart';
import 'package:local_area_network/utils/constants.dart';
import 'package:local_area_network/utils/database/database.dart';
import 'package:local_area_network/utils/device_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:collection/collection.dart';

import 'http_server/src/http_body.dart';

class DeviceDiscover {
  static const status_broadcast = "com.liuxuanping.broadcast";
  static const status_confirmed = "com.liuxuanping.confirmed";
  static const status_content = "com.liuxuanping.content";
  static const status_receive_confirmed = "cn.liuxuanping.receive_confirmed";
  RawDatagramSocket? _udpSocket;
  StreamSubscription? _streamSubscription, _httpStreamSubscription;
  HttpServer? _httpServer;
  static DeviceDiscover? _instance;
  factory DeviceDiscover() {
    if (_instance == null) {
      _instance = DeviceDiscover._internal();
    }
    return _instance!;
  }
  DeviceDiscover._internal();

  search() async {
    final DESTINATION_ADDRESS = InternetAddress("255.255.255.255");
    _udpSocket?.close();
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, appBloc.state.udpPort); // "0.0.0.0" InternetAddress.loopbackIPv4
    print("绑定${appBloc.state.udpPort}端口成功");
    _udpSocket!.broadcastEnabled = true;
    _streamSubscription = _udpSocket!.listen((e) {
      Datagram? dg = _udpSocket!.receive();

      if (dg != null) {
        String dataString = utf8.decode(dg.data);
        if (e == RawSocketEvent.read) {
          print("收到${dg.address.toString()}:${dg.port}发来的：$dataString");
          if (dataString == status_broadcast) {
            // 读到发来的广播数据，就回一个给它
            print("回复${dg.address}:${appBloc.state.udpPort} $status_confirmed");
            _udpSocket!.send(
                utf8.encode(jsonEncode({
                  "event": status_confirmed,
                  "data": DeviceInfo.deviceInfoPlusMap,
                })),
                dg.address,
                appBloc.state.udpPort);
          } else {
            Map json = jsonDecode(dataString);
            if (json['event'] == status_confirmed) {
              _udpSocket!.send(
                  utf8.encode(jsonEncode({
                    "event": status_receive_confirmed,
                    "data": DeviceInfo.deviceInfoPlusMap,
                  })),
                  dg.address,
                  appBloc.state.udpPort);

              deviceBloc.add(AddDeviceEvent(dg.address, ConnectedDevice(json: json["data"])));
            } else if (json['event'] == status_receive_confirmed) {
              deviceBloc.add(AddDeviceEvent(dg.address, ConnectedDevice(json: json["data"])));
            } else if (json['event'] == status_content) {
              clipBloc.add(ReceiveClipEvent(dg.address, ClipData.fromMap(json)));
            }
          }
        }
      }
    },
        onError: (error) {
      print("RawDatagramSocket listen发生错误：" + error.toString());
    },
        onDone: () {
      print("RawDatagramSocket listen结束");
    });
    int writtenBytesSize = _udpSocket!.send(status_broadcast.codeUnits, DESTINATION_ADDRESS, appBloc.state.udpPort);
    if (writtenBytesSize == 0) {
      _udpSocket?.close();
      // appBloc.add(PermissionEvent(1));
      Future.delayed(Duration(seconds: 3)).then((value) {
        DeviceDiscover().search();
      });
    } else {
      // appBloc.add(PermissionEvent(0));
    }
  }

  setupHttpServer() async {
    SecurityContext context = new SecurityContext();
    // final chain = Platform.script.resolve("certificates/server_chain.pem").toFilePath();
    // final key = Platform.script.resolve("certificates/server_key.pem").toFilePath();
    final chain = await rootBundle.load("assets/certificates/server_chain.pem");
    final key = await rootBundle.load("assets/certificates/server_key.pem");
    context.useCertificateChainBytes(chain.buffer.asInt8List());
    context.usePrivateKeyBytes(key.buffer.asInt8List(), password: 'uL%rvR2pVtflw24B');
    _httpServer = await HttpServer.bindSecure(InternetAddress.anyIPv4, appBloc.state.httpPort, context, shared: false);
    _httpServer?.listen((HttpRequest httpRequest) async {
      switch (httpRequest.method) {
        case 'GET':
          switch (httpRequest.uri.path) {
            case "/sync":
              final bodyMap = httpRequest.uri.queryParameters;
              String? fromDateTime = bodyMap["fromDateTime"];
              List<ClipData> data = await DbUtils().clipData.clipDataList(fromDateTime: fromDateTime);
              httpRequest.response.statusCode = HttpStatus.ok;
              httpRequest.response.write(jsonEncode(data.map((e) {
                // Uri uri = httpRequestBody.request.requestedUri;
                // uri.queryParameters["localPath"] = "";
                // uri.path = "/sync/";
                return e.copyWith(text: e.text.replaceAll('"file://', '"${httpRequest.requestedUri.origin}/sync/files?localPath=')).toMap();
              }).toList()));
              await httpRequest.response.close();
              break;
            case "/sync/files":
              final bodyMap = httpRequest.uri.queryParameters;
              final file = File(bodyMap['localPath']!);
              if (await file.exists()) {
                httpRequest.response.contentLength = await file.length();
                await httpRequest.response.addStream(file.openRead());
              } else {
                httpRequest.response.statusCode = HttpStatus.notFound;
              }
              await httpRequest.response.close();

              break;
            default:
              httpRequest.response.write('Coming soon...');
              await httpRequest.response.close();
          }
          break;
        case 'POST':
          switch (httpRequest.uri.path) {
            case "/upload":
              clipBloc.add(ProcessUploadEvent(httpRequest));
              break;
          }
          break;
        default:
          httpRequest.response.write('Coming soon...');
          await httpRequest.response.close();
      }
    });
  }

  broadcast(ClipData? clipData) {
    deviceBloc.state.devices.forEach((element) {
      print("发送到${element.ip}|${clipData!.text}");
      _udpSocket!.send(utf8.encode(jsonEncode({...clipData.toMap(), "event": status_content})), InternetAddress(element.ip!), appBloc.state.udpPort);
    });
  }

  dispose() async {
    _streamSubscription?.cancel();
    await _httpStreamSubscription?.cancel();
    _httpServer?.close();
  }
}
