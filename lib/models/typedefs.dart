import 'dart:async';

import "package:photos/models/location/location.dart";

typedef BoolCallBack = bool Function();

typedef VoidCallbackParamStr = void Function(String);
typedef VoidCallbackParamInt = void Function(int);
typedef VoidCallbackParamDouble = Function(double);
typedef VoidCallbackParamBool = void Function(bool);
typedef VoidCallbackParamListDouble = void Function(List<double>);
typedef VoidCallbackParamLocation = void Function(Location);

typedef FutureVoidCallback = Future<void> Function();
typedef FutureOrVoidCallback = FutureOr<void> Function();
typedef FutureVoidCallbackParamStr = Future<void> Function(String);
