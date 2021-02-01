// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.inapppurchase;

import static org.mockito.Mockito.when;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

public class InAppPurchasePluginTest {
  @Mock Activity activity;
  @Mock Context context;
  @Mock PluginRegistry.Registrar mockRegistrar; // For v1 embedding
  @Mock BinaryMessenger mockMessenger;
  @Mock Application mockApplication;

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
    when(mockRegistrar.activity()).thenReturn(activity);
    when(mockRegistrar.messenger()).thenReturn(mockMessenger);
    when(mockRegistrar.context()).thenReturn(context);
  }

  @Test
  public void registerWith_doNotCrashWhenRegisterContextIsActivity_V1Embedding() {
    when(mockRegistrar.context()).thenReturn(activity);
    when(activity.getApplicationContext()).thenReturn(mockApplication);
    InAppPurchasePlugin.registerWith(mockRegistrar);
  }
}
