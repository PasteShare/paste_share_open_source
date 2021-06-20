import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_area_network/bloc/clip_bloc.dart';
import 'package:local_area_network/pages/home.dart';
import 'package:local_area_network/utils/constants.dart';
import 'package:local_area_network/utils/database/database.dart';
import 'package:local_area_network/utils/device_info.dart';
import 'package:local_area_network/utils/http.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'bloc/app_bloc.dart';
import 'bloc/device_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.white, systemNavigationBarIconBrightness: Brightness.dark);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  await SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
  httpsHandler();
  await getDeviceInfo();
  await DbUtils().init();
  clipBloc = ClipBloc(initialState: ClipState(kIsWeb ? [] : await DbUtils().clipData.clipDataList()));
  deviceBloc = DeviceBloc(initialState: DeviceState(kIsWeb ? [] : await DbUtils().connectedDevice.list()));
  appBloc = AppBloc(AppState());
  runApp(MultiBlocProvider(providers: [
    BlocProvider(create: (BuildContext context) => appBloc),
    BlocProvider(create: (BuildContext context) => deviceBloc),
    BlocProvider(create: (BuildContext context) => clipBloc),
  ], child: MyApp()));
}

httpsHandler() {
  HttpOverrides.global = DevHttpOverrides();
}

getDeviceInfo() async {
  MethodChannel channel = MethodChannel('dev.fluttercommunity.plus/device_info');
  if (kIsWeb) {
    DeviceInfo.deviceInfoPlusMap = await DeviceInfoPlugin().webBrowserInfo;
  } else if (Platform.isAndroid) {
    DeviceInfo.deviceInfoPlusMap = (await channel.invokeMethod('getAndroidDeviceInfo')).cast<String, dynamic>();
    DeviceInfo.deviceInfoPlusMap['systemFeatures'] = [];
  } else if (Platform.isIOS) {
    DeviceInfo.deviceInfoPlusMap = (await channel.invokeMethod('getIosDeviceInfo')).cast<String, dynamic>();
  } else if (Platform.isMacOS) {
    DeviceInfo.deviceInfoPlusMap = (await channel.invokeMethod('getMacosDeviceInfo')).cast<String, dynamic>();
  } else if (Platform.isWindows) {
    final windowsInfo = await DeviceInfoPlugin().windowsInfo;
    DeviceInfo.deviceInfoPlusMap = {"computerName": windowsInfo.computerName, "numberOfCores": windowsInfo.numberOfCores, "systemMemoryInMegabytes": windowsInfo.systemMemoryInMegabytes};
  } else if (Platform.isLinux) {
    final linuxInfo = await DeviceInfoPlugin().linuxInfo;
    DeviceInfo.deviceInfoPlusMap = {"id": linuxInfo.id, "buildId": linuxInfo.buildId, "idLike": linuxInfo.idLike.toString(), "machineId": linuxInfo.machineId, "name": linuxInfo.name, "prettyName": linuxInfo.prettyName, "variant": linuxInfo.variant, "variantId": linuxInfo.variantId, "version": linuxInfo.version, "versionCodename": linuxInfo.versionCodename, "versionId": linuxInfo.versionId};
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appDisplayName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF51aa4d,
          <int, Color>{
            50: Color(0xFFE8F5E9),
            100: Color(0xFFC8E6C9),
            200: Color(0xFFA5D6A7),
            300: Color(0xFF81C784),
            400: Color(0xFF66BB6A),
            500: Color(0xFF51aa4d),
            600: Color(0xFF43A047),
            700: Color(0xFF388E3C),
            800: Color(0xFF2E7D32),
            900: Color(0xFF1B5E20),
          },
        ),
        // accentColor: Colors.white
        // accentColor: MaterialColor(
        //   0xFF51aa4d,
        //   <int, Color>{
        //     50: Color(0xFFE8F5E9),
        //     100: Color(0xFFC8E6C9),
        //     200: Color(0xFFA5D6A7),
        //     300: Color(0xFF81C784),
        //     400: Color(0xFF66BB6A),
        //     500: Color(0xFF51aa4d),
        //     600: Color(0xFF43A047),
        //     700: Color(0xFF388E3C),
        //     800: Color(0xFF2E7D32),
        //     900: Color(0xFF1B5E20),
        //   },
        // ) // MaterialColor(0x51aa4d, {}),
      ),
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      // home: MyHomePage(title: 'Flutter Demo Home Page'),
      home: MyHomePage(title: "PasteShare"),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key key, this.title}) : super(key: key);
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Invoke "debug painting" (press "p" in the console, choose the
//           // "Toggle Debug Paint" action from the Flutter Inspector in Android
//           // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//           // to see the wireframe for each widget.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headline4,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
