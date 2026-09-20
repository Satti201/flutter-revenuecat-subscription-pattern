import 'package:purchases_flutter/purchases_flutter.dart';

import 'subscription_remote_datasource.dart';

class SubscriptionRemoteDataSourceImpl
    implements SubscriptionRemoteDataSource {
  @override
  Future<CustomerInfo> getCustomerInfo() {
    return Purchases.getCustomerInfo();
  }

  @override
  Future<Offerings> getOfferings() {
    return Purchases.getOfferings();
  }

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchase(
      PurchaseParams.package(package),
    );

    return result.customerInfo;
  }

  @override
  Future<CustomerInfo> restorePurchases() {
    return Purchases.restorePurchases();
  }
}
