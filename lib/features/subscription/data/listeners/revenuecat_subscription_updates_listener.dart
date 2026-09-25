import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/entities/subscription_entity.dart';
import '../mappers/subscription_mapper.dart';
import 'subscription_updates_listener.dart';

class RevenueCatSubscriptionUpdatesListener
    implements SubscriptionUpdatesListener {
  RevenueCatSubscriptionUpdatesListener();

  final Map<void Function(SubscriptionEntity), void Function(CustomerInfo)>
      _callbacks = {};

  @override
  void add(void Function(SubscriptionEntity subscription) listener) {
    void revenueCatCallback(CustomerInfo customerInfo) {
      final subscription =
          SubscriptionMapper.toSubscriptionEntity(customerInfo);
      listener(subscription);
    }

    _callbacks[listener] = revenueCatCallback;
    Purchases.addCustomerInfoUpdateListener(revenueCatCallback);
  }

  @override
  void remove(void Function(SubscriptionEntity subscription) listener) {
    final callback = _callbacks.remove(listener);
    if (callback != null) {
      Purchases.removeCustomerInfoUpdateListener(callback);
    }
  }
}
