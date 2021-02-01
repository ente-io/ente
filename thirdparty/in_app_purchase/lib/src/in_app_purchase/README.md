# in_app_purchase

A simplified, generic API for handling in app purchases with a single code base.

You can use this to:

* Display a list of products for sale from App Store (on iOS) or Google Play (on
  Android)
* Purchase a product. From the App Store this supports consumables,
  non-consumables, and subscriptions. From Google Play this supports both in app
  purchases and subscriptions.
* Load previously purchased products, to the extent that this is supported in
  both underlying platforms.

This can be used in addition to or as an alternative to
[billing_client_wrappers](../billing_client_wrappers/README.md) and
[store_kit_wrappers](../store_kit_wrappers/README.md).

`InAppPurchaseConnection` tries to be as platform agnostic as possible, but in
some cases differentiating between the underlying platforms is unavoidable.

You can see a sample usage of this in the [example
app](../../../example/README.md).
