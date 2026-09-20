import 'package:purchases_flutter/purchases_flutter.dart';

abstract class SubscriptionRemoteDataSource {
  Future<CustomerInfo> getCustomerInfo();

  Future<Offerings> getOfferings();

  Future<CustomerInfo> purchasePackage(Package package);

  Future<CustomerInfo> restorePurchases();
}
