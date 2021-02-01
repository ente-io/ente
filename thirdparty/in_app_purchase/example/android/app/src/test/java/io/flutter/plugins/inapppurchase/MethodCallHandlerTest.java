package io.flutter.plugins.inapppurchase;

import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.ACKNOWLEDGE_PURCHASE;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.CONSUME_PURCHASE_ASYNC;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.END_CONNECTION;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.IS_READY;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.LAUNCH_BILLING_FLOW;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.ON_DISCONNECT;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.ON_PURCHASES_UPDATED;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.QUERY_PURCHASES;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.QUERY_PURCHASE_HISTORY_ASYNC;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.QUERY_SKU_DETAILS;
import static io.flutter.plugins.inapppurchase.InAppPurchasePlugin.MethodNames.START_CONNECTION;
import static io.flutter.plugins.inapppurchase.Translator.fromBillingResult;
import static io.flutter.plugins.inapppurchase.Translator.fromPurchaseHistoryRecordList;
import static io.flutter.plugins.inapppurchase.Translator.fromPurchasesList;
import static io.flutter.plugins.inapppurchase.Translator.fromPurchasesResult;
import static io.flutter.plugins.inapppurchase.Translator.fromSkuDetailsList;
import static java.util.Arrays.asList;
import static java.util.Collections.singletonList;
import static java.util.Collections.unmodifiableList;
import static java.util.stream.Collectors.toList;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.refEq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.SkuType;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.ConsumeResponseListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.Purchase.PurchasesResult;
import com.android.billingclient.api.PurchaseHistoryRecord;
import com.android.billingclient.api.PurchaseHistoryResponseListener;
import com.android.billingclient.api.SkuDetails;
import com.android.billingclient.api.SkuDetailsParams;
import com.android.billingclient.api.SkuDetailsResponseListener;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Before;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;

public class MethodCallHandlerTest {
  private MethodCallHandlerImpl methodChannelHandler;
  private BillingClientFactory factory;
  @Mock BillingClient mockBillingClient;
  @Mock MethodChannel mockMethodChannel;
  @Spy Result result;
  @Mock Activity activity;
  @Mock Context context;
  @Mock ActivityPluginBinding mockActivityPluginBinding;

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
    factory =
        (@NonNull Context context,
            @NonNull MethodChannel channel,
            boolean enablePendingPurchases) -> mockBillingClient;
    methodChannelHandler = new MethodCallHandlerImpl(activity, context, mockMethodChannel, factory);
    when(mockActivityPluginBinding.getActivity()).thenReturn(activity);
  }

  @Test
  public void invalidMethod() {
    MethodCall call = new MethodCall("invalid", null);
    methodChannelHandler.onMethodCall(call, result);
    verify(result, times(1)).notImplemented();
  }

  @Test
  public void isReady_true() {
    mockStartConnection();
    MethodCall call = new MethodCall(IS_READY, null);
    when(mockBillingClient.isReady()).thenReturn(true);
    methodChannelHandler.onMethodCall(call, result);
    verify(result).success(true);
  }

  @Test
  public void isReady_false() {
    mockStartConnection();
    MethodCall call = new MethodCall(IS_READY, null);
    when(mockBillingClient.isReady()).thenReturn(false);
    methodChannelHandler.onMethodCall(call, result);
    verify(result).success(false);
  }

  @Test
  public void isReady_clientDisconnected() {
    MethodCall disconnectCall = new MethodCall(END_CONNECTION, null);
    methodChannelHandler.onMethodCall(disconnectCall, mock(Result.class));
    MethodCall isReadyCall = new MethodCall(IS_READY, null);

    methodChannelHandler.onMethodCall(isReadyCall, result);

    verify(result).error(contains("UNAVAILABLE"), contains("BillingClient"), any());
    verify(result, never()).success(any());
  }

  @Test
  public void startConnection() {
    ArgumentCaptor<BillingClientStateListener> captor = mockStartConnection();
    verify(result, never()).success(any());
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    captor.getValue().onBillingSetupFinished(billingResult);

    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void startConnection_multipleCalls() {
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", 1);
    arguments.put("enablePendingPurchases", true);
    MethodCall call = new MethodCall(START_CONNECTION, arguments);
    ArgumentCaptor<BillingClientStateListener> captor =
        ArgumentCaptor.forClass(BillingClientStateListener.class);
    doNothing().when(mockBillingClient).startConnection(captor.capture());

    methodChannelHandler.onMethodCall(call, result);
    verify(result, never()).success(any());
    BillingResult billingResult1 =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    BillingResult billingResult2 =
        BillingResult.newBuilder()
            .setResponseCode(200)
            .setDebugMessage("dummy debug message")
            .build();
    BillingResult billingResult3 =
        BillingResult.newBuilder()
            .setResponseCode(300)
            .setDebugMessage("dummy debug message")
            .build();

    captor.getValue().onBillingSetupFinished(billingResult1);
    captor.getValue().onBillingSetupFinished(billingResult2);
    captor.getValue().onBillingSetupFinished(billingResult3);

    verify(result, times(1)).success(fromBillingResult(billingResult1));
    verify(result, times(1)).success(any());
  }

  @Test
  public void endConnection() {
    // Set up a connected BillingClient instance
    final int disconnectCallbackHandle = 22;
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", disconnectCallbackHandle);
    arguments.put("enablePendingPurchases", true);
    MethodCall connectCall = new MethodCall(START_CONNECTION, arguments);
    ArgumentCaptor<BillingClientStateListener> captor =
        ArgumentCaptor.forClass(BillingClientStateListener.class);
    doNothing().when(mockBillingClient).startConnection(captor.capture());
    methodChannelHandler.onMethodCall(connectCall, mock(Result.class));
    final BillingClientStateListener stateListener = captor.getValue();

    // Disconnect the connected client
    MethodCall disconnectCall = new MethodCall(END_CONNECTION, null);
    methodChannelHandler.onMethodCall(disconnectCall, result);

    // Verify that the client is disconnected and that the OnDisconnect callback has
    // been triggered
    verify(result, times(1)).success(any());
    verify(mockBillingClient, times(1)).endConnection();
    stateListener.onBillingServiceDisconnected();
    Map<String, Integer> expectedInvocation = new HashMap<>();
    expectedInvocation.put("handle", disconnectCallbackHandle);
    verify(mockMethodChannel, times(1)).invokeMethod(ON_DISCONNECT, expectedInvocation);
  }

  @Test
  public void querySkuDetailsAsync() {
    // Connect a billing client and set up the SKU query listeners
    establishConnectedBillingClient(/* arguments= */ null, /* result= */ null);
    String skuType = BillingClient.SkuType.INAPP;
    List<String> skusList = asList("id1", "id2");
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("skuType", skuType);
    arguments.put("skusList", skusList);
    MethodCall queryCall = new MethodCall(QUERY_SKU_DETAILS, arguments);

    // Query for SKU details
    methodChannelHandler.onMethodCall(queryCall, result);

    // Assert the arguments were forwarded correctly to BillingClient
    ArgumentCaptor<SkuDetailsParams> paramCaptor = ArgumentCaptor.forClass(SkuDetailsParams.class);
    ArgumentCaptor<SkuDetailsResponseListener> listenerCaptor =
        ArgumentCaptor.forClass(SkuDetailsResponseListener.class);
    verify(mockBillingClient).querySkuDetailsAsync(paramCaptor.capture(), listenerCaptor.capture());
    assertEquals(paramCaptor.getValue().getSkuType(), skuType);
    assertEquals(paramCaptor.getValue().getSkusList(), skusList);

    // Assert that we handed result BillingClient's response
    int responseCode = 200;
    List<SkuDetails> skuDetailsResponse = asList(buildSkuDetails("foo"));
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    listenerCaptor.getValue().onSkuDetailsResponse(billingResult, skuDetailsResponse);
    ArgumentCaptor<HashMap<String, Object>> resultCaptor = ArgumentCaptor.forClass(HashMap.class);
    verify(result).success(resultCaptor.capture());
    HashMap<String, Object> resultData = resultCaptor.getValue();
    assertEquals(resultData.get("billingResult"), fromBillingResult(billingResult));
    assertEquals(resultData.get("skuDetailsList"), fromSkuDetailsList(skuDetailsResponse));
  }

  @Test
  public void querySkuDetailsAsync_clientDisconnected() {
    // Disconnect the Billing client and prepare a querySkuDetails call
    MethodCall disconnectCall = new MethodCall(END_CONNECTION, null);
    methodChannelHandler.onMethodCall(disconnectCall, mock(Result.class));
    String skuType = BillingClient.SkuType.INAPP;
    List<String> skusList = asList("id1", "id2");
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("skuType", skuType);
    arguments.put("skusList", skusList);
    MethodCall queryCall = new MethodCall(QUERY_SKU_DETAILS, arguments);

    // Query for SKU details
    methodChannelHandler.onMethodCall(queryCall, result);

    // Assert that we sent an error back.
    verify(result).error(contains("UNAVAILABLE"), contains("BillingClient"), any());
    verify(result, never()).success(any());
  }

  @Test
  public void launchBillingFlow_ok_null_AccountId() {
    // Fetch the sku details first and then prepare the launch billing flow call
    String skuId = "foo";
    queryForSkus(singletonList(skuId));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", null);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    // Launch the billing flow
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    when(mockBillingClient.launchBillingFlow(any(), any())).thenReturn(billingResult);
    methodChannelHandler.onMethodCall(launchCall, result);

    // Verify we pass the arguments to the billing flow
    ArgumentCaptor<BillingFlowParams> billingFlowParamsCaptor =
        ArgumentCaptor.forClass(BillingFlowParams.class);
    verify(mockBillingClient).launchBillingFlow(any(), billingFlowParamsCaptor.capture());
    BillingFlowParams params = billingFlowParamsCaptor.getValue();
    assertEquals(params.getSku(), skuId);
    assertNull(params.getAccountId());

    // Verify we pass the response code to result
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void launchBillingFlow_ok_null_OldSku() {
    // Fetch the sku details first and then prepare the launch billing flow call
    String skuId = "foo";
    String accountId = "account";
    queryForSkus(singletonList(skuId));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    arguments.put("oldSku", null);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    // Launch the billing flow
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    when(mockBillingClient.launchBillingFlow(any(), any())).thenReturn(billingResult);
    methodChannelHandler.onMethodCall(launchCall, result);

    // Verify we pass the arguments to the billing flow
    ArgumentCaptor<BillingFlowParams> billingFlowParamsCaptor =
        ArgumentCaptor.forClass(BillingFlowParams.class);
    verify(mockBillingClient).launchBillingFlow(any(), billingFlowParamsCaptor.capture());
    BillingFlowParams params = billingFlowParamsCaptor.getValue();
    assertEquals(params.getSku(), skuId);
    assertEquals(params.getAccountId(), accountId);
    assertNull(params.getOldSku());
    // Verify we pass the response code to result
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void launchBillingFlow_ok_null_Activity() {
    methodChannelHandler.setActivity(null);

    // Fetch the sku details first and then prepare the launch billing flow call
    String skuId = "foo";
    String accountId = "account";
    queryForSkus(singletonList(skuId));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);
    methodChannelHandler.onMethodCall(launchCall, result);

    // Verify we pass the response code to result
    verify(result).error(contains("ACTIVITY_UNAVAILABLE"), contains("foreground"), any());
    verify(result, never()).success(any());
  }

  @Test
  public void launchBillingFlow_ok_oldSku() {
    // Fetch the sku details first and query the method call
    String skuId = "foo";
    String accountId = "account";
    String oldSkuId = "oldFoo";
    queryForSkus(unmodifiableList(asList(skuId, oldSkuId)));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    arguments.put("oldSku", oldSkuId);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    // Launch the billing flow
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    when(mockBillingClient.launchBillingFlow(any(), any())).thenReturn(billingResult);
    methodChannelHandler.onMethodCall(launchCall, result);

    // Verify we pass the arguments to the billing flow
    ArgumentCaptor<BillingFlowParams> billingFlowParamsCaptor =
        ArgumentCaptor.forClass(BillingFlowParams.class);
    verify(mockBillingClient).launchBillingFlow(any(), billingFlowParamsCaptor.capture());
    BillingFlowParams params = billingFlowParamsCaptor.getValue();
    assertEquals(params.getSku(), skuId);
    assertEquals(params.getAccountId(), accountId);
    assertEquals(params.getOldSku(), oldSkuId);

    // Verify we pass the response code to result
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void launchBillingFlow_ok_AccountId() {
    // Fetch the sku details first and query the method call
    String skuId = "foo";
    String accountId = "account";
    queryForSkus(singletonList(skuId));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    // Launch the billing flow
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    when(mockBillingClient.launchBillingFlow(any(), any())).thenReturn(billingResult);
    methodChannelHandler.onMethodCall(launchCall, result);

    // Verify we pass the arguments to the billing flow
    ArgumentCaptor<BillingFlowParams> billingFlowParamsCaptor =
        ArgumentCaptor.forClass(BillingFlowParams.class);
    verify(mockBillingClient).launchBillingFlow(any(), billingFlowParamsCaptor.capture());
    BillingFlowParams params = billingFlowParamsCaptor.getValue();
    assertEquals(params.getSku(), skuId);
    assertEquals(params.getAccountId(), accountId);

    // Verify we pass the response code to result
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void launchBillingFlow_ok_Proration() {
    // Fetch the sku details first and query the method call
    String skuId = "foo";
    String oldSkuId = "oldFoo";
    String accountId = "account";
    int prorationMode = BillingFlowParams.ProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE;
    queryForSkus(unmodifiableList(asList(skuId, oldSkuId)));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    arguments.put("oldSku", oldSkuId);
    arguments.put("prorationMode", prorationMode);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    // Launch the billing flow
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    when(mockBillingClient.launchBillingFlow(any(), any())).thenReturn(billingResult);
    methodChannelHandler.onMethodCall(launchCall, result);

    // Verify we pass the arguments to the billing flow
    ArgumentCaptor<BillingFlowParams> billingFlowParamsCaptor =
        ArgumentCaptor.forClass(BillingFlowParams.class);
    verify(mockBillingClient).launchBillingFlow(any(), billingFlowParamsCaptor.capture());
    BillingFlowParams params = billingFlowParamsCaptor.getValue();
    assertEquals(params.getSku(), skuId);
    assertEquals(params.getAccountId(), accountId);
    assertEquals(params.getOldSku(), oldSkuId);
    assertEquals(params.getReplaceSkusProrationMode(), prorationMode);

    // Verify we pass the response code to result
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void launchBillingFlow_ok_Proration_with_null_OldSku() {
    // Fetch the sku details first and query the method call
    String skuId = "foo";
    String accountId = "account";
    String queryOldSkuId = "oldFoo";
    String oldSkuId = null;
    int prorationMode = BillingFlowParams.ProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE;
    queryForSkus(unmodifiableList(asList(skuId, queryOldSkuId)));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    arguments.put("oldSku", oldSkuId);
    arguments.put("prorationMode", prorationMode);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    // Launch the billing flow
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    when(mockBillingClient.launchBillingFlow(any(), any())).thenReturn(billingResult);
    methodChannelHandler.onMethodCall(launchCall, result);

    // Assert that we sent an error back.
    verify(result)
        .error(
            contains("IN_APP_PURCHASE_REQUIRE_OLD_SKU"),
            contains("launchBillingFlow failed because oldSku is null"),
            any());
    verify(result, never()).success(any());
  }

  @Test
  public void launchBillingFlow_clientDisconnected() {
    // Prepare the launch call after disconnecting the client
    MethodCall disconnectCall = new MethodCall(END_CONNECTION, null);
    methodChannelHandler.onMethodCall(disconnectCall, mock(Result.class));
    String skuId = "foo";
    String accountId = "account";
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    methodChannelHandler.onMethodCall(launchCall, result);

    // Assert that we sent an error back.
    verify(result).error(contains("UNAVAILABLE"), contains("BillingClient"), any());
    verify(result, never()).success(any());
  }

  @Test
  public void launchBillingFlow_skuNotFound() {
    // Try to launch the billing flow for a random sku ID
    establishConnectedBillingClient(null, null);
    String skuId = "foo";
    String accountId = "account";
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    methodChannelHandler.onMethodCall(launchCall, result);

    // Assert that we sent an error back.
    verify(result).error(contains("NOT_FOUND"), contains(skuId), any());
    verify(result, never()).success(any());
  }

  @Test
  public void launchBillingFlow_oldSkuNotFound() {
    // Try to launch the billing flow for a random sku ID
    establishConnectedBillingClient(null, null);
    String skuId = "foo";
    String accountId = "account";
    String oldSkuId = "oldSku";
    queryForSkus(singletonList(skuId));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("sku", skuId);
    arguments.put("accountId", accountId);
    arguments.put("oldSku", oldSkuId);
    MethodCall launchCall = new MethodCall(LAUNCH_BILLING_FLOW, arguments);

    methodChannelHandler.onMethodCall(launchCall, result);

    // Assert that we sent an error back.
    verify(result).error(contains("IN_APP_PURCHASE_INVALID_OLD_SKU"), contains(oldSkuId), any());
    verify(result, never()).success(any());
  }

  @Test
  public void queryPurchases() {
    establishConnectedBillingClient(null, null);
    PurchasesResult purchasesResult = mock(PurchasesResult.class);
    Purchase purchase = buildPurchase("foo");
    when(purchasesResult.getPurchasesList()).thenReturn(asList(purchase));
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    when(purchasesResult.getBillingResult()).thenReturn(billingResult);
    when(mockBillingClient.queryPurchases(SkuType.INAPP)).thenReturn(purchasesResult);

    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("skuType", SkuType.INAPP);
    methodChannelHandler.onMethodCall(new MethodCall(QUERY_PURCHASES, arguments), result);

    // Verify we pass the response to result
    ArgumentCaptor<HashMap<String, Object>> resultCaptor = ArgumentCaptor.forClass(HashMap.class);
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(resultCaptor.capture());
    assertEquals(fromPurchasesResult(purchasesResult), resultCaptor.getValue());
  }

  @Test
  public void queryPurchases_clientDisconnected() {
    // Prepare the launch call after disconnecting the client
    methodChannelHandler.onMethodCall(new MethodCall(END_CONNECTION, null), mock(Result.class));

    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("skuType", SkuType.INAPP);
    methodChannelHandler.onMethodCall(new MethodCall(QUERY_PURCHASES, arguments), result);

    // Assert that we sent an error back.
    verify(result).error(contains("UNAVAILABLE"), contains("BillingClient"), any());
    verify(result, never()).success(any());
  }

  @Test
  public void queryPurchaseHistoryAsync() {
    // Set up an established billing client and all our mocked responses
    establishConnectedBillingClient(null, null);
    ArgumentCaptor<HashMap<String, Object>> resultCaptor = ArgumentCaptor.forClass(HashMap.class);
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    List<PurchaseHistoryRecord> purchasesList = asList(buildPurchaseHistoryRecord("foo"));
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("skuType", SkuType.INAPP);
    ArgumentCaptor<PurchaseHistoryResponseListener> listenerCaptor =
        ArgumentCaptor.forClass(PurchaseHistoryResponseListener.class);

    methodChannelHandler.onMethodCall(
        new MethodCall(QUERY_PURCHASE_HISTORY_ASYNC, arguments), result);

    // Verify we pass the data to result
    verify(mockBillingClient)
        .queryPurchaseHistoryAsync(eq(SkuType.INAPP), listenerCaptor.capture());
    listenerCaptor.getValue().onPurchaseHistoryResponse(billingResult, purchasesList);
    verify(result).success(resultCaptor.capture());
    HashMap<String, Object> resultData = resultCaptor.getValue();
    assertEquals(fromBillingResult(billingResult), resultData.get("billingResult"));
    assertEquals(
        fromPurchaseHistoryRecordList(purchasesList), resultData.get("purchaseHistoryRecordList"));
  }

  @Test
  public void queryPurchaseHistoryAsync_clientDisconnected() {
    // Prepare the launch call after disconnecting the client
    methodChannelHandler.onMethodCall(new MethodCall(END_CONNECTION, null), mock(Result.class));

    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("skuType", SkuType.INAPP);
    methodChannelHandler.onMethodCall(
        new MethodCall(QUERY_PURCHASE_HISTORY_ASYNC, arguments), result);

    // Assert that we sent an error back.
    verify(result).error(contains("UNAVAILABLE"), contains("BillingClient"), any());
    verify(result, never()).success(any());
  }

  @Test
  public void onPurchasesUpdatedListener() {
    PluginPurchaseListener listener = new PluginPurchaseListener(mockMethodChannel);

    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    List<Purchase> purchasesList = asList(buildPurchase("foo"));
    ArgumentCaptor<HashMap<String, Object>> resultCaptor = ArgumentCaptor.forClass(HashMap.class);
    doNothing()
        .when(mockMethodChannel)
        .invokeMethod(eq(ON_PURCHASES_UPDATED), resultCaptor.capture());
    listener.onPurchasesUpdated(billingResult, purchasesList);

    HashMap<String, Object> resultData = resultCaptor.getValue();
    assertEquals(fromBillingResult(billingResult), resultData.get("billingResult"));
    assertEquals(fromPurchasesList(purchasesList), resultData.get("purchasesList"));
  }

  @Test
  public void consumeAsync() {
    establishConnectedBillingClient(null, null);
    ArgumentCaptor<BillingResult> resultCaptor = ArgumentCaptor.forClass(BillingResult.class);
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("purchaseToken", "mockToken");
    arguments.put("developerPayload", "mockPayload");
    ArgumentCaptor<ConsumeResponseListener> listenerCaptor =
        ArgumentCaptor.forClass(ConsumeResponseListener.class);

    methodChannelHandler.onMethodCall(new MethodCall(CONSUME_PURCHASE_ASYNC, arguments), result);

    ConsumeParams params =
        ConsumeParams.newBuilder()
            .setDeveloperPayload("mockPayload")
            .setPurchaseToken("mockToken")
            .build();

    // Verify we pass the data to result
    verify(mockBillingClient).consumeAsync(refEq(params), listenerCaptor.capture());

    listenerCaptor.getValue().onConsumeResponse(billingResult, "mockToken");
    verify(result).success(resultCaptor.capture());

    // Verify we pass the response code to result
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void acknowledgePurchase() {
    establishConnectedBillingClient(null, null);
    ArgumentCaptor<BillingResult> resultCaptor = ArgumentCaptor.forClass(BillingResult.class);
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    HashMap<String, Object> arguments = new HashMap<>();
    arguments.put("purchaseToken", "mockToken");
    arguments.put("developerPayload", "mockPayload");
    ArgumentCaptor<AcknowledgePurchaseResponseListener> listenerCaptor =
        ArgumentCaptor.forClass(AcknowledgePurchaseResponseListener.class);

    methodChannelHandler.onMethodCall(new MethodCall(ACKNOWLEDGE_PURCHASE, arguments), result);

    AcknowledgePurchaseParams params =
        AcknowledgePurchaseParams.newBuilder()
            .setDeveloperPayload("mockPayload")
            .setPurchaseToken("mockToken")
            .build();

    // Verify we pass the data to result
    verify(mockBillingClient).acknowledgePurchase(refEq(params), listenerCaptor.capture());

    listenerCaptor.getValue().onAcknowledgePurchaseResponse(billingResult);
    verify(result).success(resultCaptor.capture());

    // Verify we pass the response code to result
    verify(result, never()).error(any(), any(), any());
    verify(result, times(1)).success(fromBillingResult(billingResult));
  }

  @Test
  public void endConnection_if_activity_dettached() {
    InAppPurchasePlugin plugin = new InAppPurchasePlugin();
    plugin.setMethodCallHandler(methodChannelHandler);
    mockStartConnection();
    plugin.onDetachedFromActivity();
    verify(mockBillingClient).endConnection();
  }

  private ArgumentCaptor<BillingClientStateListener> mockStartConnection() {
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", 1);
    arguments.put("enablePendingPurchases", true);
    MethodCall call = new MethodCall(START_CONNECTION, arguments);
    ArgumentCaptor<BillingClientStateListener> captor =
        ArgumentCaptor.forClass(BillingClientStateListener.class);
    doNothing().when(mockBillingClient).startConnection(captor.capture());

    methodChannelHandler.onMethodCall(call, result);
    return captor;
  }

  private void establishConnectedBillingClient(
      @Nullable Map<String, Object> arguments, @Nullable Result result) {
    if (arguments == null) {
      arguments = new HashMap<>();
      arguments.put("handle", 1);
      arguments.put("enablePendingPurchases", true);
    }
    if (result == null) {
      result = mock(Result.class);
    }

    MethodCall connectCall = new MethodCall(START_CONNECTION, arguments);
    methodChannelHandler.onMethodCall(connectCall, result);
  }

  private void queryForSkus(List<String> skusList) {
    // Set up the query method call
    establishConnectedBillingClient(/* arguments= */ null, /* result= */ null);
    HashMap<String, Object> arguments = new HashMap<>();
    String skuType = SkuType.INAPP;
    arguments.put("skuType", skuType);
    arguments.put("skusList", skusList);
    MethodCall queryCall = new MethodCall(QUERY_SKU_DETAILS, arguments);

    // Call the method.
    methodChannelHandler.onMethodCall(queryCall, mock(Result.class));

    // Respond to the call with a matching set of Sku details.
    ArgumentCaptor<SkuDetailsResponseListener> listenerCaptor =
        ArgumentCaptor.forClass(SkuDetailsResponseListener.class);
    verify(mockBillingClient).querySkuDetailsAsync(any(), listenerCaptor.capture());
    List<SkuDetails> skuDetailsResponse =
        skusList.stream().map(this::buildSkuDetails).collect(toList());
    BillingResult billingResult =
        BillingResult.newBuilder()
            .setResponseCode(100)
            .setDebugMessage("dummy debug message")
            .build();
    listenerCaptor.getValue().onSkuDetailsResponse(billingResult, skuDetailsResponse);
  }

  private SkuDetails buildSkuDetails(String id) {
    SkuDetails details = mock(SkuDetails.class);
    when(details.getSku()).thenReturn(id);
    return details;
  }

  private Purchase buildPurchase(String orderId) {
    Purchase purchase = mock(Purchase.class);
    when(purchase.getOrderId()).thenReturn(orderId);
    return purchase;
  }

  private PurchaseHistoryRecord buildPurchaseHistoryRecord(String purchaseToken) {
    PurchaseHistoryRecord purchase = mock(PurchaseHistoryRecord.class);
    when(purchase.getPurchaseToken()).thenReturn(purchaseToken);
    return purchase;
  }
}
