// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';

typedef void AdditionalSteps(dynamic args);

class StubInAppPurchasePlatform {
  Map<String, dynamic> _expectedCalls = <String, dynamic>{};
  Map<String, AdditionalSteps> _additionalSteps = <String, AdditionalSteps>{};
  void addResponse(
      {String name,
      dynamic value,
      AdditionalSteps additionalStepBeforeReturn}) {
    _additionalSteps[name] = additionalStepBeforeReturn;
    _expectedCalls[name] = value;
  }

  List<MethodCall> _previousCalls = <MethodCall>[];
  List<MethodCall> get previousCalls => _previousCalls;
  MethodCall previousCallMatching(String name) => _previousCalls
      .firstWhere((MethodCall call) => call.method == name, orElse: () => null);
  int countPreviousCalls(String name) =>
      _previousCalls.where((MethodCall call) => call.method == name).length;

  void reset() {
    _expectedCalls.clear();
    _previousCalls.clear();
    _additionalSteps.clear();
  }

  Future<dynamic> fakeMethodCallHandler(MethodCall call) async {
    _previousCalls.add(call);
    if (_expectedCalls.containsKey(call.method)) {
      if (_additionalSteps[call.method] != null) {
        _additionalSteps[call.method](call.arguments);
      }
      return Future<dynamic>.sync(() => _expectedCalls[call.method]);
    } else {
      return Future<void>.sync(() => null);
    }
  }
}
