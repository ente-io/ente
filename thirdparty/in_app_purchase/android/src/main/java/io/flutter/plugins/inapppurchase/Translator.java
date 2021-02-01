// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.flutter.plugins.inapppurchase;

import androidx.annotation.Nullable;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.Purchase.PurchasesResult;
import com.android.billingclient.api.PurchaseHistoryRecord;
import com.android.billingclient.api.SkuDetails;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

/** Handles serialization of {@link com.android.billingclient.api.BillingClient} related objects. */
/*package*/ class Translator {
  static HashMap<String, Object> fromSkuDetail(SkuDetails detail) {
    HashMap<String, Object> info = new HashMap<>();
    info.put("title", detail.getTitle());
    info.put("description", detail.getDescription());
    info.put("freeTrialPeriod", detail.getFreeTrialPeriod());
    info.put("introductoryPrice", detail.getIntroductoryPrice());
    info.put("introductoryPriceAmountMicros", detail.getIntroductoryPriceAmountMicros());
    info.put("introductoryPriceCycles", detail.getIntroductoryPriceCycles());
    info.put("introductoryPricePeriod", detail.getIntroductoryPricePeriod());
    info.put("price", detail.getPrice());
    info.put("priceAmountMicros", detail.getPriceAmountMicros());
    info.put("priceCurrencyCode", detail.getPriceCurrencyCode());
    info.put("sku", detail.getSku());
    info.put("type", detail.getType());
    info.put("isRewarded", detail.isRewarded());
    info.put("subscriptionPeriod", detail.getSubscriptionPeriod());
    info.put("originalPrice", detail.getOriginalPrice());
    info.put("originalPriceAmountMicros", detail.getOriginalPriceAmountMicros());
    return info;
  }

  static List<HashMap<String, Object>> fromSkuDetailsList(
      @Nullable List<SkuDetails> skuDetailsList) {
    if (skuDetailsList == null) {
      return Collections.emptyList();
    }

    ArrayList<HashMap<String, Object>> output = new ArrayList<>();
    for (SkuDetails detail : skuDetailsList) {
      output.add(fromSkuDetail(detail));
    }
    return output;
  }

  static HashMap<String, Object> fromPurchase(Purchase purchase) {
    HashMap<String, Object> info = new HashMap<>();
    info.put("orderId", purchase.getOrderId());
    info.put("packageName", purchase.getPackageName());
    info.put("purchaseTime", purchase.getPurchaseTime());
    info.put("purchaseToken", purchase.getPurchaseToken());
    info.put("signature", purchase.getSignature());
    info.put("sku", purchase.getSku());
    info.put("isAutoRenewing", purchase.isAutoRenewing());
    info.put("originalJson", purchase.getOriginalJson());
    info.put("developerPayload", purchase.getDeveloperPayload());
    info.put("isAcknowledged", purchase.isAcknowledged());
    info.put("purchaseState", purchase.getPurchaseState());
    return info;
  }

  static HashMap<String, Object> fromPurchaseHistoryRecord(
      PurchaseHistoryRecord purchaseHistoryRecord) {
    HashMap<String, Object> info = new HashMap<>();
    info.put("purchaseTime", purchaseHistoryRecord.getPurchaseTime());
    info.put("purchaseToken", purchaseHistoryRecord.getPurchaseToken());
    info.put("signature", purchaseHistoryRecord.getSignature());
    info.put("sku", purchaseHistoryRecord.getSku());
    info.put("developerPayload", purchaseHistoryRecord.getDeveloperPayload());
    info.put("originalJson", purchaseHistoryRecord.getOriginalJson());
    return info;
  }

  static List<HashMap<String, Object>> fromPurchasesList(@Nullable List<Purchase> purchases) {
    if (purchases == null) {
      return Collections.emptyList();
    }

    List<HashMap<String, Object>> serialized = new ArrayList<>();
    for (Purchase purchase : purchases) {
      serialized.add(fromPurchase(purchase));
    }
    return serialized;
  }

  static List<HashMap<String, Object>> fromPurchaseHistoryRecordList(
      @Nullable List<PurchaseHistoryRecord> purchaseHistoryRecords) {
    if (purchaseHistoryRecords == null) {
      return Collections.emptyList();
    }

    List<HashMap<String, Object>> serialized = new ArrayList<>();
    for (PurchaseHistoryRecord purchaseHistoryRecord : purchaseHistoryRecords) {
      serialized.add(fromPurchaseHistoryRecord(purchaseHistoryRecord));
    }
    return serialized;
  }

  static HashMap<String, Object> fromPurchasesResult(PurchasesResult purchasesResult) {
    HashMap<String, Object> info = new HashMap<>();
    info.put("responseCode", purchasesResult.getResponseCode());
    info.put("billingResult", fromBillingResult(purchasesResult.getBillingResult()));
    info.put("purchasesList", fromPurchasesList(purchasesResult.getPurchasesList()));
    return info;
  }

  static HashMap<String, Object> fromBillingResult(BillingResult billingResult) {
    HashMap<String, Object> info = new HashMap<>();
    info.put("responseCode", billingResult.getResponseCode());
    info.put("debugMessage", billingResult.getDebugMessage());
    return info;
  }
}
