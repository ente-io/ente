import 'dart:async';

import "package:photos/models/location/location.dart";

typedef FutureVoidCallback = Future<void> Function();
typedef BoolCallBack = bool Function();
typedef FutureVoidCallbackParamStr = Future<void> Function(String);
typedef VoidCallbackParamStr = void Function(String);
typedef FutureOrVoidCallback = FutureOr<void> Function();
typedef VoidCallbackParamInt = void Function(int);
typedef VoidCallbackParamLocation = void Function(Location);
typedef VoidCallbackParamListDouble = void Function(List<double>);
