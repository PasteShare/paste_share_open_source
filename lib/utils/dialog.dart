import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class AppDialog {
  static AppDialog _instance = AppDialog._internal();
  int count = 0;

  factory AppDialog() {
    return _instance;
  }
  AppDialog._internal();
  showSingle(inputContext, { onButton1Pressed, onButton2Pressed }) async {
    if (count > 0) {
      return;
    }
    count++;
    await showDialog(context: inputContext, builder: (context) {
      return AlertDialog(
        actions: [
          TextButton(onPressed: (){
            if (onButton1Pressed != null) {
              onButton1Pressed();
            }
            closeSingle(context);
          }, child: Text(AppLocalizations.of(context)!.iKnow)),
          TextButton(onPressed: (){
            if (onButton2Pressed != null) {
              onButton2Pressed();
            }
            closeSingle(context);
            openAppSettings();
          }, child: Text(AppLocalizations.of(context)!.goSettings))
        ],
        content: Text(AppLocalizations.of(context)!.turnOnYourLocalNetworkSettings),
      );
    });
  }
  closeSingle(context) async {
    if (count > 0) {
      await Navigator.of(context).maybePop();
      count = 0;
    }
  }
}