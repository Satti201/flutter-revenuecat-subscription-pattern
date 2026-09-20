import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';

class RevenueCatService {
  static Future<void> initialize() async {
    RevenueCatConfig.validate();

    final configuration = PurchasesConfiguration(
      RevenueCatConfig.apiKey,
    );

    await Purchases.configure(configuration);
  }
}
