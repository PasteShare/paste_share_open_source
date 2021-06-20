import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hydrated_bloc/hydrated_bloc.dart';

@immutable
class AppState {
  final int httpPort;
  final int udpPort;
  final int noPermission;
  AppState({this.httpPort = 1111, this.udpPort = 55556, this.noPermission = 0});
  AppState copyWith({int? httpPort, int? udpPort, int? noPermission}) => AppState(httpPort:  httpPort ?? this.httpPort, udpPort: udpPort ?? this.udpPort, noPermission: noPermission ?? this.noPermission);
}
@immutable
abstract class AppEvent {
  const AppEvent();
}
@immutable
class PermissionEvent extends AppEvent {
  final int noPermission;
  const PermissionEvent(this.noPermission);
}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc(AppState initialState) : super(initialState);

  @override
  Stream<AppState> mapEventToState(AppEvent event) async* {
    if (event is PermissionEvent) {
      if (state.noPermission != event.noPermission) {
        yield state.copyWith(noPermission: event.noPermission);
      }

    }
  }
}
