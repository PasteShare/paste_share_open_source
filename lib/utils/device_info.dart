import 'dart:io';

import 'package:flutter/foundation.dart';

class DeviceInfo {
  static dynamic deviceInfoPlus;
  static dynamic deviceInfoPlusMap;
  @override
  String toString() {
    return super.toString();
  }

  static getDeviceId({Map? deviceInfo}) {
    String deviceId = "";
    if (deviceInfo == null) {
      deviceInfo = deviceInfoPlusMap;
    }
    if (deviceInfo?["androidId"] != null) {
      // Android
      deviceId = deviceInfo?["androidId"];
    } else if (deviceInfo?["systemName"] != null && deviceInfo?["systemName"] == "iOS") {
      deviceId = deviceInfo?["identifierForVendor"];
    } else if (deviceInfo?["hostName"] != null && deviceInfo?["hostName"] == "Darwin") {
      deviceId = deviceInfo?["computerName"];
    } else if (deviceInfo?["machineId"] != null) {
      deviceId = deviceInfo?["machineId"];
    } else if (deviceInfo?["computerName"] != null) {
      deviceId = deviceInfo?["computerName"];
    }
    return deviceId;
  }

  static getDeviceName({Map? deviceInfo}) {
    String name = "";
    if (deviceInfo?["androidId"] != null) {
      // Android
      name = deviceInfo?["manufacturer"] + " " + deviceInfo?["model"];
    } else if (deviceInfo?["systemName"] != null && deviceInfo?["systemName"] == "iOS") {
      name = deviceInfo?["name"];
    } else if (deviceInfo?["hostName"] != null && deviceInfo?["hostName"] == "Darwin") {
      name = deviceInfo?["computerName"];
    } else if (deviceInfo?["prettyName"] != null) {
      name = deviceInfo?["prettyName"];
    } else if (deviceInfo?["computerName"] != null) {
      name = deviceInfo?["computerName"];
    }
    return name;
  }
}
