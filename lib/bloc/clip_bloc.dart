import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:local_area_network/utils/constants.dart';
import 'package:local_area_network/utils/database/database.dart';
import 'package:local_area_network/utils/device_discover.dart';
import 'package:local_area_network/utils/http.dart';
import 'package:local_area_network/utils/http_server/http_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class ClipState {
  final List<ClipData> clipDataList;
  const ClipState(this.clipDataList);
  ClipState copyWith({List<ClipData>? clipDataList}) => ClipState(clipDataList ?? this.clipDataList);
}

@immutable
abstract class ClipEvent {
  const ClipEvent();
}

@immutable
class ClearClipEvent extends ClipEvent {
  const ClearClipEvent();
}

@immutable
class ReceiveClipEvent extends ClipEvent {
  final InternetAddress internetAddress;
  final ClipData clipData;
  const ReceiveClipEvent(this.internetAddress, this.clipData);
}
@immutable
class ClipProgressEvent extends ClipEvent {
  final double percent;
  final int id;
  const ClipProgressEvent(this.id, this.percent);
}
@immutable
class ClipUnit8Event extends ClipEvent {
  final List<int> data;
  const ClipUnit8Event(this.data);
}
class ProcessUploadEvent extends ClipEvent {
  final HttpRequest httpRequest;
  const ProcessUploadEvent(this.httpRequest);
}

@immutable
class SaveClipEvent extends ClipEvent {
  final ClipData clipData;
  const SaveClipEvent(this.clipData);
}

@immutable
class SyncClipEvent extends ClipEvent {
  const SyncClipEvent();
}
@immutable
class DismissClipEvent extends ClipEvent {
  final DismissDirection direction;
  final ClipData clipData;
  const DismissClipEvent(this.direction, this.clipData);
}
@immutable
class NewClipDataListEvent extends ClipEvent {
  final List<ClipData> clipDataList;
  const NewClipDataListEvent(this.clipDataList);
}

class ClipBloc extends Bloc<ClipEvent, ClipState> {
  ClipBloc({required ClipState initialState}) : super(initialState);

  uploadFile(List<String> filePaths) async {
    if (filePaths.length == 0) {
      return;
    }
    deviceBloc.state.devices.forEach((device) async {
      MultipartRequest request = MultipartRequest("POST", Uri.https("${device.ip}:${appBloc.state.httpPort}", "/upload"));
      final multipartFileList = await Future.wait(filePaths.map((filePath) {
        final nameArray = filePath.split("/");
        return MultipartFile.fromPath(nameArray[nameArray.length - 1], filePath);
      }));
      request.files.addAll(multipartFileList);
      StreamedResponse _streamedResponse = await request.send();
      final result = await _streamedResponse.stream.bytesToString();
      print("upload result: " + result.toString());
    });
  }

  _isFile(ClipData inputClipData) {
    return _isLocalFile(inputClipData) || _isRemoteFile(inputClipData);
  }
  _isLocalFile(ClipData inputClipData) {
    return inputClipData.text.startsWith('["file://') && inputClipData.text.endsWith('"]');
  }
  _isRemoteFile(ClipData inputClipData) {
    return inputClipData.text.startsWith('["https://') && inputClipData.text.endsWith('"]');
  }

  Future<ClipData?> _save(ClipData inputClipData, int fromDeviceId) async {
    // element.deviceId == fromDeviceId && !element.text.startsWith('["file://') && !element.text.startsWith('["https://')
    final firstClipData = state.clipDataList.firstWhereOrNull((element) {
      if (element.text == inputClipData.text) {
        return true;
      }
      return false;
    });
    if (firstClipData == null) {
      ClipData clipData = inputClipData.copyWith(deviceId: fromDeviceId);
      final id = await DbUtils().clipData.insertClipData(clipData);
      clipData = (await DbUtils().clipData.get(id))!;
      return clipData;
    }
    return null;
  }

  _sendToOtherDevice(ClipData clipData) async {
    if (clipData.text.startsWith("[\"") && clipData.text.endsWith("\"]")) {
      final filePathList = (jsonDecode(clipData.text) as List).cast<String>();
      final onlyFilePathList = filePathList.where((filePath) => filePath.toString().startsWith("file://")).toList();
      final realFilePathList = onlyFilePathList.map((filePath) => filePath.replaceFirst("file://", "")).toList();
      await uploadFile(realFilePathList);
    } else {
      DeviceDiscover().broadcast(clipData);
    }
  }

  @override
  Stream<ClipState> mapEventToState(ClipEvent event) async* {
    if (event is ReceiveClipEvent) {
      final devices = deviceBloc.state.devices;
      /// TODO: 这里有bug，如果两个设备共用了同一个ip会导致剪切板数据来源错误
      ConnectedDevice? fromDevice = devices.firstWhereOrNull((element) => (element.ip == event.internetAddress.address));
      if (fromDevice != null) {
        ClipData? newClipData = await _save(event.clipData, fromDevice.id);
        if (newClipData == null) {
          return;
        }
        yield ClipState([...state.clipDataList..insert(0, newClipData)]);
        final rootPath = await getApplicationSupportDirectory();
        if (newClipData.text.startsWith('["https://') && newClipData.text.endsWith('"]')) {
          final filePathList = await Future.wait((jsonDecode(newClipData.text) as List).map((element) async {
            Uri uri = Uri.parse(element);
            final fileResponse = await LocalApiClient().send(Request("GET", uri));
            final filePath = join(rootPath.path, basename(uri.queryParameters['localPath']!));
            final downloadFile = File(filePath); // .writeAsBytes(imageResponse.bodyBytes, flush: true);
            int total = 0;
            double percent = 0.00;
            final sink = downloadFile.openWrite();
            await fileResponse.stream.map((event) {
              total += event.length;
              double newPercent = double.parse((total / fileResponse.contentLength!).toStringAsFixed(3));
              if (newPercent != percent) {
                percent = newPercent;
                emit(state.copyWith(clipDataList: state.clipDataList.map((ClipData e) {
                  if (e.id == newClipData.id) {
                    final progressMap = e.progressMap;
                    progressMap[element] = newPercent;
                    return e.copyWith(progressMap: progressMap);
                  }
                  return e;
                }).toList()));
              }
              return event;
            }).pipe(sink);

            return "file://" + filePath;
          }));
          final localFilePathClipData = newClipData.copyWith(text: jsonEncode(filePathList));
          yield state.copyWith(clipDataList: state.clipDataList.map((e) => e.id == newClipData.id ? localFilePathClipData : e).toList());
          DbUtils().clipData.updateClipData(localFilePathClipData);
          // emit();
        }
      }
    } else if (event is SaveClipEvent) {
      ClipData? clipData = await _save(event.clipData, 0);
      if (clipData != null) {
        yield ClipState([...state.clipDataList..insert(0, clipData)]);
        await _sendToOtherDevice(clipData);
      }
    } else if (event is SyncClipEvent) {
      List<ConnectedDevice?> devices = deviceBloc.state.devices;
      devices.forEach((device) {
        post(Uri.https(device!.ip!, "/sync"));
      });
    } else if (event is ClearClipEvent) {
      await DbUtils().clipData.clear();
      final directory = await getApplicationSupportDirectory();
      final files = await directory.list().toList();
      await Future.wait(files.map((event) async {
        event.delete();
      }));
      yield ClipState([]);
    } else if (event is ProcessUploadEvent) {
      final httpRequest = event.httpRequest;
      ConnectedDevice? fromDevice = deviceBloc.state.devices.firstWhereOrNull((element) => element.ip == httpRequest.connectionInfo!.remoteAddress.address);
      if (fromDevice == null) {
        throw "device is not found";
      }
      ClipData? clipData = await _save(ClipData(text: ""), fromDevice.id);
      state.clipDataList.insert(0, clipData!);
      yield ClipState([ ...state.clipDataList ]);
      int total = 0; double percent = 0.0;
      // HttpRequestBody httpRequestBody = await HttpBodyHandler.processRequest(httpRequest, callback: (List<int> data) {
      //   total += data.length;
      //   double newPercent = double.parse((total / httpRequest.contentLength).toStringAsFixed(2));
      //   if (newPercent != percent) {
      //     percent = newPercent;
      //     print("percent: " + percent.toString());
      //     add(ClipProgressEvent(clipData.id, newPercent));
      //   }
      // });
      HttpRequestBody httpRequestBody = await HttpBodyHandler.processRequest(httpRequest, callback: (List<int> data) {
        total += data.length;
        double newPercent = double.parse((total / httpRequest.contentLength).toStringAsFixed(3));
        if (newPercent != percent) {
          percent = newPercent;
          emit(ClipState(state.clipDataList.map((ClipData e) {
            if (e.id == clipData.id) {
              return e.copyWith(progress: newPercent);
            }
            return e;
          }).toList()));
        }
      });
      final Map<String, dynamic>? bodyMap = httpRequestBody.body;
      final directory = await getApplicationSupportDirectory();
      if (httpRequestBody.body is Map) {
        final List<String> uploadFilePaths = [];
        Iterable<Future<dynamic>> futures = bodyMap!.entries.map((entry) async {
          final key = entry.key; final uploadFile = entry.value;
          if (uploadFile is HttpBodyFileUpload) {
            final path = join(directory.path, uploadFile.filename);
            uploadFilePaths.add("file://" + path);
            File targetFile = File(path);
            if (await targetFile.exists()) {
              await targetFile.delete();
            }
            await targetFile.writeAsBytes(uploadFile.content, flush: true);
          } else {
            // 额外字段处理

          }
          return uploadFile;
        });
        await Future.wait(futures);
        yield ClipState(state.clipDataList.map((e) {
          if (e.id == clipData.id) {
            final newClipData = e.copyWith(text: jsonEncode(uploadFilePaths));
            DbUtils().clipData.updateClipData(newClipData);
            return newClipData;
          }
          return e;
        }).toList());
      }
      httpRequestBody.request.response.write(jsonEncode({
        "message": "success",
      }));
      httpRequestBody.request.response.close();
    } else if (event is ClipProgressEvent) {
      print("${event.id} event.percent: " + event.percent.toString());
      yield ClipState(state.clipDataList.map((ClipData e) {
        if (e.id == event.id) {
          return e.copyWith(progress: event.percent);
        }
        return e;
      }).toList());
    } else if (event is NewClipDataListEvent) {
      yield state.copyWith(clipDataList: event.clipDataList.toList());
    }
  }

  @override
  void onEvent(ClipEvent event) {
    // print("event" + event.toString());
    super.onEvent(event);
  }

  @override
  Stream<Transition<ClipEvent, ClipState>> transformEvents(Stream<ClipEvent> events, transitionFn) {
    // return super.transformEvents(events, transitionFn);
    return events.flatMap(transitionFn);
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
