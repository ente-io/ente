// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.inapppurchase;

import android.content.Context;
import androidx.annotation.NonNull;
import com.android.billingclient.api.BillingClient;
import io.flutter.plugin.common.MethodChannel;

/** Responsible for creating a {@link BillingClient} object. */
interface BillingClientFactory {

  /**
   * Creates and returns a {@link BillingClient}.
   *
   * @param context The context used to create the {@link BillingClient}.
   * @param channel The method channel used to create the {@link BillingClient}.
   * @param enablePendingPurchases Whether to enable pending purchases. Throws an exception if it is
   *     false.
   * @return The {@link BillingClient} object that is created.
   */
  BillingClient createBillingClient(
      @NonNull Context context, @NonNull MethodChannel channel, boolean enablePendingPurchases);
}
