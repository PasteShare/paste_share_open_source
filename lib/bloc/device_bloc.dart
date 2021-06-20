import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_area_network/utils/database/database.dart';
import 'package:local_area_network/utils/device_discover.dart';
import 'package:collection/collection.dart';
import 'package:local_area_network/utils/device_info.dart';
// import 'package:hydrated_bloc/hydrated_bloc.dart';

@immutable
class DeviceState {
  final List<ConnectedDevice> devices;
  DeviceState(this.devices);
}

@immutable
abstract class DeviceEvent {
  const DeviceEvent();
}

@immutable
class SearchDeviceEvent extends DeviceEvent {
  const SearchDeviceEvent();
}

@immutable
class AddDeviceEvent extends DeviceEvent {
  final InternetAddress internetAddress;
  final ConnectedDevice connectedDevice;
  const AddDeviceEvent(this.internetAddress, this.connectedDevice);
}

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  DeviceBloc({required DeviceState initialState}) : super(initialState);

  @override
  Stream<DeviceState> mapEventToState(DeviceEvent event) async* {
    if (kIsWeb) {
      return;
    }
    if (event is SearchDeviceEvent) {
      DeviceDiscover().search();
      DeviceDiscover().setupHttpServer();
    } else if (event is AddDeviceEvent) {
      final oldDevices = state.devices;
      Map deviceInfo = event.connectedDevice.json!;
      String deviceId = DeviceInfo.getDeviceId(deviceInfo: deviceInfo);
      String name = DeviceInfo.getDeviceName(deviceInfo: deviceInfo);
      if (deviceId == DeviceInfo.getDeviceId()) { // 自己发来的消息不处理
        return;
      }
      // try {
      ConnectedDevice? oldDevice = oldDevices.firstWhereOrNull((element) => (element.deviceId == deviceId || event.internetAddress.address == element.ip));
      if (oldDevice != null) {
        oldDevices.remove(oldDevice);
        final newDevice = oldDevice.copyWith(isOnline: true, name: name, ip: event.internetAddress.address, json: event.connectedDevice.json, deviceId: deviceId);
        await DbUtils().connectedDevice.update(newDevice);
        oldDevices.insert(0, newDevice);
      } else {
        final id = await DbUtils().connectedDevice.insert(deviceId: deviceId, name: name, ip: event.internetAddress.address, json: event.connectedDevice.json);
        oldDevice = await DbUtils().connectedDevice.get(id);
        oldDevices.insert(0, oldDevice!.copyWith(isOnline: true));
      }
      yield DeviceState([...oldDevices]);
      // } catch (e) {
      //   print("存入device失败了：" + e.toString());
      // }

    }
  }
}
