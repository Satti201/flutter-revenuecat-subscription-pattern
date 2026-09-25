import 'package:purchases_flutter/purchases_flutter.dart';

import 'customer_info_listener.dart';

class RevenueCatCustomerInfoListener implements CustomerInfoListener {
  const RevenueCatCustomerInfoListener();

  @override
  void add(void Function(CustomerInfo customerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  @override
  void remove(void Function(CustomerInfo customerInfo) listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}
