// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

/// Method channel for the plugin's platform<-->Dart calls (all but the
/// ios->Dart calls which are carried over the [callbackChannel]).
const MethodChannel channel =
    MethodChannel('plugins.flutter.io/in_app_purchase');

/// Method channel for the plugin's ios->Dart calls.
// This is in a separate channel due to historic reasons only.
// TODO(cyanglaz): Remove this. https://github.com/flutter/flutter/issues/69225
const MethodChannel callbackChannel =
    MethodChannel('plugins.flutter.io/in_app_purchase_callback');
