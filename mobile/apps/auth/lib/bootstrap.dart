// ignore_for_file: deprecated_member_use

import "dart:async";
import "dart:developer";

import "package:bloc/bloc.dart";
import "package:flutter/widgets.dart";

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log("onChange(${bloc.runtimeType}, $change)");
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log("onError(${bloc.runtimeType}, $error, $stackTrace)");
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  await runZonedGuarded(
    () async {
      Bloc.observer = AppBlocObserver();
      runApp(await builder());
    },
    (error, stackTrace) => log(error.toString(), stackTrace: stackTrace),
  );
}
