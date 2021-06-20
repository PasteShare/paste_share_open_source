import 'dart:async';
import 'dart:convert';
import 'dart:io';

// import 'package:clipboard_monitor/clipboard_monitor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:local_area_network/bloc/app_bloc.dart';

import 'package:local_area_network/bloc/clip_bloc.dart';
import 'package:local_area_network/bloc/device_bloc.dart';
import 'package:local_area_network/utils/constants.dart';
import 'package:local_area_network/utils/database/database.dart';
import 'package:local_area_network/utils/device_discover.dart';
import 'package:local_area_network/utils/dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share/share.dart';
import 'package:path/path.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';

class PasteIntent extends Intent {}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  String wlanIP = "";
  StreamSubscription? _shareMediaSubscription, _shareTextSubscription;
  final copyKeySet = LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC);
  final pasteKeySet = LogicalKeySet(Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control, LogicalKeyboardKey.keyV);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      return;
    }
    WidgetsBinding.instance!.addObserver(this);
    if (Platform.isIOS || Platform.isAndroid) {
      // ClipboardMonitor.unregisterAllCallbacks();
      // ClipboardMonitor.registerCallback(onClipboardText);
    }

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _getWlanIP();
      _dealShare();
    });
  }

  _dealShare() {
    if (Platform.isIOS || Platform.isAndroid) {
      ReceiveSharingIntent.getInitialText().then(_onClipboardText);
      ReceiveSharingIntent.getInitialMedia().then(_dealShareFiles);
      _shareMediaSubscription = ReceiveSharingIntent.getMediaStream().listen(_dealShareFiles);
      _shareTextSubscription = ReceiveSharingIntent.getTextStream().listen(_onClipboardText);
    }
  }

  _dealShareFiles(List<SharedMediaFile> sharedMediaFiles) {
    if (sharedMediaFiles.length > 0) {
      clipBloc.add(SaveClipEvent(ClipData(
          text: jsonEncode(sharedMediaFiles.map((e) {
        return "file://${e.path}";
      }).toList()))));
    }
  }

  _getWlanIP() async {
    Timer.periodic(Duration(seconds: 3), (timer) {
      get(Uri.https("lan.liuxuanping.com", "/")).then((value) {
        deviceBloc.add(SearchDeviceEvent());
        timer.cancel();
      }).catchError((onError) {
        print("没联网？" + onError.toString());
      });
    });
    final networkInterfaceList = await NetworkInterface.list();
    for (var interface in networkInterfaceList) {
      interface.addresses.forEach((element) {
        if (element.type == InternetAddressType.IPv4 && element.address.startsWith("192.168.")) {
          setState(() {
            wlanIP = element.address;
          });
        }
      });
      // if (interface.name == "wlan0" || interface.name == "en0" || interface.name == "WLAN") {
      //
      // } else {
      //   interface.addresses.forEach((element) {
      //     if (element.type == InternetAddressType.IPv4) {
      //       setState(() {
      //         wlanIP = element.address;
      //       });
      //     }
      //   });
      // }
    }
    if (wlanIP.isEmpty) {
      for (var interface in networkInterfaceList) {
        interface.addresses.forEach((element) {
          if (element.type == InternetAddressType.IPv4) {
            setState(() {
              wlanIP = element.address;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    // if (Platform.isIOS || Platform.isAndroid) {
    //   ClipboardMonitor.unregisterCallback(_onClipboardText);
    // }
    DeviceDiscover().dispose();
    _shareMediaSubscription?.cancel();
    _shareTextSubscription?.cancel();
    super.dispose();
  }

  void _onClipboardText(String? text) {
    print("clipboard changed: $text");
    if (text != null && text.isNotEmpty) {
      clipBloc.add(SaveClipEvent(ClipData(text: text, deviceId: 0)));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _dealAppResumed();
        break;
      default:
    }
  }

  _dealAppResumed() async {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.white, systemNavigationBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
      await Future.delayed(Duration(milliseconds: 1000));
    }
    await _getClipboardData();
  }

  _getFlutterClipboardData() async {
    ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
      String text = clipboardData.text!;
      final clipTextArray = text.split("\n");
      if (clipTextArray[0] == "x-special/nautilus-clipboard") {
        try {
          text = '[';
          clipTextArray.sublist(2, clipTextArray.length - 1).forEach((element) {
            text = text + '"$element",';
          });
          text += "]";
          text = text.replaceFirst('",]', '"]');
          if (clipTextArray[1] == "copy") {}
        } catch (e) {
          print(e);
        }
      }
      clipBloc.add(SaveClipEvent(ClipData(text: text)));
    }
  }

  _getClipboardData() async {
    if (Platform.isMacOS || Platform.isWindows) {
      final filePaths = await ReceiveSharingIntent.readClipboard();
      if (Platform.isMacOS && filePaths != null && filePaths.length > 0 && filePaths[0].startsWith("file://")) {
        List<String> list = ["-rf"];
        filePaths.forEach((e) => list.add(e.toString().replaceFirst("file://", "").replaceAll("%20", " ")));
        final d = await getApplicationSupportDirectory();
        list.add(d.path);
        ProcessResult processResult = await Process.run("cp", list);
        clipBloc.add(SaveClipEvent(ClipData(text: jsonEncode(filePaths.map((e) => "file://" + join(d.path, basename(e.toString().replaceAll("%20", " ")))).toList()))));
      } else {
        _getFlutterClipboardData();
      }
    } else {
      _getFlutterClipboardData();
    }
  }

  _copy(ClipData clipData) async {
    if (clipData.text.isEmpty) {
      return;
    }
    if (clipData.text.startsWith('["file://') && clipData.text.endsWith('"]')) {
      final d = await getApplicationSupportDirectory();
      if (Platform.isMacOS) {
        Process.run("open", [d.path]);
      } else if (Platform.isWindows) {
        Process.run("explorer", [d.path]);
      } else if (Platform.isLinux) {
        Process.run("nautilus", [d.path]);
      } else {
        Share.shareFiles((jsonDecode(clipData.text) as List).map((e) => e.toString().replaceFirst("file://", "")).toList());
      }
    } else if (clipData.text.startsWith('["https://')) {
    } else {
      Clipboard.setData(ClipboardData(text: clipData.text));
    }
  }

  _clear() {
    clipBloc.add(ClearClipEvent());
  }

  _openHelp(context) {
    launch("https://lan.liuxuanping.com/help.html?locale=" + Localizations.localeOf(context).toString());
  }

  @override
  Widget build(BuildContext context) {
    // final TextEditingController _textEditingController = TextEditingController();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    print(Theme.of(context).brightness);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.appDisplayName),
            Text(wlanIP.isNotEmpty ? "$wlanIP:1111" : "", style: TextStyle(fontSize: 10)),
          ],
        ),
        actions: [
          BlocListener<AppBloc, AppState>(
              listener: (context, state) async {
                if (state.noPermission == 1) {
                  AppDialog().showSingle(context);
                } else if (state.noPermission == 0) {
                  try {
                    await AppDialog().closeSingle(context);
                  } catch (e) {
                    await Future.delayed(Duration(seconds: 3));
                    await AppDialog().closeSingle(context);
                  }
                }
              },
              listenWhen: (previous, current) {
                return previous.noPermission != current.noPermission;
              },
              child: Container()),
          IconButton(icon: Icon(Icons.clear_all_sharp), onPressed: _clear),
          FocusableActionDetector(
              autofocus: true,
              shortcuts: {
                pasteKeySet: PasteIntent(),
              },
              actions: {
                PasteIntent: CallbackAction(onInvoke: (e) {
                  return _getClipboardData.call();
                })
              },
              child: Container()),
        ],
      ),
      drawer: Container(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.white,
        width: 220,
        padding: EdgeInsets.only(top: kToolbarHeight),
        child: BlocBuilder<DeviceBloc, DeviceState>(
          builder: (context, state) {
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    _openHelp(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(AppLocalizations.of(context)!.connectedDevices), SizedBox(width: 4), Icon(Icons.help_outline_rounded, size: 16)],
                  ),
                ),
                BlocBuilder<DeviceBloc, DeviceState>(builder: (context, state) {
                  return Column(
                    children: state.devices.map((device) {
                      return ListTile(
                        onTap: () {
                          print("ListTile onTap");
                        },
                        enableFeedback: true,
                        title: Text(device.name ?? ""),
                        subtitle: Text(device.ip ?? ""),
                        trailing: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: device.isOnline ? Colors.green : Colors.redAccent, borderRadius: BorderRadius.all(Radius.circular(10))),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            );
          },
        ),
      ),
      body: Container(
          child: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: RefreshIndicator(onRefresh: () async {
          await Future.wait(deviceBloc.state.devices.map((ConnectedDevice? device) async {
            final lastClip = clipBloc.state.clipDataList.firstWhereOrNull((element) => element.deviceId == device!.id);
            Map<String, dynamic>? query;
            if (lastClip != null) {
              query = {"fromDateTime": lastClip.createdAt};
            }

            /// TODO: 不知道对象的port号
            final response = await get(Uri.https(device!.ip! + ":" + appBloc.state.httpPort.toString(), "/sync", query));
            final responseJson = jsonDecode(response.body) as List;
            responseJson.reversed.forEach((clipDataMap) {
              final clipData = ClipData.fromMap(clipDataMap);
              clipBloc.add(ReceiveClipEvent(InternetAddress(device.ip!), clipData));
            });
          }));
        }, child: BlocBuilder<ClipBloc, ClipState>(
          builder: (context, state) {
            if (state.clipDataList.length > 0) {
              return ListView.builder(
                itemCount: state.clipDataList.length,
                itemBuilder: (context, index) {
                  final item = state.clipDataList[index];
                  final text = item.text;
                  Widget itemWidget = Text(state.clipDataList[index].text);
                  if (item.text.isEmpty) {
                    itemWidget = CircularProgressIndicator(
                      value: item.progress,
                      // valueColor: Theme.of(context).primaryColor,
                      semanticsLabel: 'Linear progress indicator',
                      backgroundColor: Color(0x06000000),
                    );
                  } else if ((text.startsWith("[\"file://") || text.startsWith("[\"https://")) && text.endsWith("\"]")) {
                    final filePathList = jsonDecode(text) as List;

                    itemWidget = Row(
                      mainAxisSize: MainAxisSize.max,
                      children: filePathList.map((filePath) {
                        String extensionName = extension(filePath).toLowerCase();
                        if (extensionName.isNotEmpty) {
                          if (extensionName == ".jpg" || extensionName == ".png" || extensionName == ".jpeg" || extensionName == ".gif") {
                            final path = filePath.replaceFirst("file://", "");
                            return SizedBox(
                              width: 100,
                              height: 100,
                              child: text.startsWith("[\"file://")
                                  ? Image.file(File(path), width: 100, height: 100)
                                  : Center(
                                      child: CircularProgressIndicator(
                                        value: item.progressMap[filePath] ?? 0,
                                        // valueColor: Theme.of(context).primaryColor,
                                        semanticsLabel: 'Linear progress indicator',
                                        backgroundColor: Color(0x06000000),
                                      ),
                                    ),
                            );
                          } else {
                            return Column(
                              children: [
                                SizedBox(
                                  width: Theme.of(context).iconTheme.size,
                                  height: Theme.of(context).iconTheme.size,
                                  child: text.startsWith("[\"file://")
                                      ? Icon(Icons.insert_drive_file_sharp)
                                      : CircularProgressIndicator(
                                          value: item.progressMap[filePath] ?? 0,
                                          // valueColor: Theme.of(context).primaryColor,
                                          backgroundColor: Color(0x06000000),
                                          semanticsLabel: 'Linear progress indicator',
                                        ),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  constraints: BoxConstraints(maxWidth: 100),
                                  child: Text(
                                    basename(filePath),
                                    style: TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }
                        }
                        return itemWidget = CircularProgressIndicator(
                          value: item.progress,
                          // valueColor: Theme.of(context).primaryColor,
                          backgroundColor: Color(0x06000000),
                          semanticsLabel: 'Linear progress indicator',
                        );
                      }).toList(),
                    );
                  }
                  return Dismissible(
                      // confirmDismiss: (direction) async {
                      //   // await Future.delayed(Duration(seconds: 3));
                      //   return Future.value(false);
                      // },
                      // background: Text("test1"),
                      // secondaryBackground: Text("test2"),
                      key: Key(state.clipDataList[index].createdAt!),
                      onDismissed: (direction) {
                        ClipData deletedClipData = state.clipDataList.removeAt(index);
                        clipBloc.add(NewClipDataListEvent(state.clipDataList));
                        Timer t = Timer(Duration(seconds: 3), () {
                          if (deletedClipData.text.startsWith('["file://')) {
                            (jsonDecode(deletedClipData.text) as List).forEach((element) async {
                              final file = File(element.toString().replaceFirst('file://', ""));
                              if (await file.exists()) {
                                await file.delete();
                              }
                            });
                          }
                          DbUtils().clipData.deleteClipData(deletedClipData.id);
                        });
                        // Show a snackbar. This snackbar could also contain "Undo" actions.
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            duration: Duration(seconds: 3),
                            action: SnackBarAction(
                              label: AppLocalizations.of(context)!.undo,
                              onPressed: () {
                                t.cancel();
                                state.clipDataList.insert(index, deletedClipData);
                                clipBloc.add(NewClipDataListEvent(state.clipDataList));
                              },
                            ),
                            padding: EdgeInsets.only(left: 16),
                            // margin: EdgeInsets.zero,
                            // backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.white,
                            content: Text("deleted", style: TextStyle())));
                      },
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          onTap: () {
                            _copy(state.clipDataList[index]);
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [itemWidget],
                            ),
                          ),
                        ),
                      ));
                },
              );
            }
            String tips = "Command + V";
            if (Platform.isAndroid || Platform.isIOS) {
              tips = AppLocalizations.of(context)!.helpTips;
            } else if (Platform.isWindows) {
              tips = "Ctrol + V";
            }
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 100),
                  child: Center(child: Text(tips, style: TextStyle(), textAlign: TextAlign.center)),
                ),
              ],
            );
          },
        )),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (Platform.isAndroid) {
            FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              List<String> filePaths = result.paths.map((path) => "file://" + path!).toList();
              clipBloc.add(SaveClipEvent(ClipData(text: jsonEncode(filePaths))));
            } else {
              // User canceled the picker
            }
          } else if (Platform.isIOS) {
            final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              clipBloc.add(SaveClipEvent(ClipData(text: jsonEncode(["file://${pickedFile.path}"]))));
            }
          } else {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
              content: Text('暂未实现'),
            ));
          }
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
