import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/data/listeners/customer_info_listener.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:premium_flow/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  test('subscriptionCustomerInfoSyncProvider updates subscription state on CustomerInfo update',
      () async {
    final fakeListener = _FakeCustomerInfoListener();

    final container = ProviderContainer(
      overrides: [
        customerInfoListenerProvider.overrideWithValue(fakeListener),
        subscriptionNotifierProvider.overrideWith(
          () => _FakeSubscriptionNotifier(const SubscriptionEntity.free()),
        ),
      ],
    );

    // Initial state is free
    final initial = await container.read(subscriptionNotifierProvider.future);
    expect(initial.status, equals(SubscriptionStatus.free));

    // Activate sync provider
    container.read(subscriptionCustomerInfoSyncProvider);
    expect(fakeListener.listeners.length, equals(1));

    // Simulate RevenueCat emitting CustomerInfo with active premium entitlement
    final premiumCustomerInfo = CustomerInfo.fromJson(const {
      'entitlements': {
        'all': {
          'premium': {
            'identifier': 'premium',
            'isActive': true,
            'willRenew': true,
            'periodType': 'normal',
            'latestPurchaseDate': '2026-09-01T00:00:00Z',
            'originalPurchaseDate': '2026-09-01T00:00:00Z',
            'expirationDate': '2027-09-01T00:00:00Z',
            'store': 'app_store',
            'productIdentifier': 'premium_monthly',
            'isSandbox': true,
            'unsubscribeDetectedAt': null,
            'billingIssueDetectedAt': null,
          }
        },
        'active': {
          'premium': {
            'identifier': 'premium',
            'isActive': true,
            'willRenew': true,
            'periodType': 'normal',
            'latestPurchaseDate': '2026-09-01T00:00:00Z',
            'originalPurchaseDate': '2026-09-01T00:00:00Z',
            'expirationDate': '2027-09-01T00:00:00Z',
            'store': 'app_store',
            'productIdentifier': 'premium_monthly',
            'isSandbox': true,
            'unsubscribeDetectedAt': null,
            'billingIssueDetectedAt': null,
          }
        },
      },
      'activeSubscriptions': ['premium_monthly'],
      'allPurchasedProductIdentifiers': ['premium_monthly'],
      'nonSubscriptionTransactions': [],
      'firstSeen': '2026-01-01T00:00:00Z',
      'originalAppUserId': 'test_user',
      'requestDate': '2026-09-25T00:00:00Z',
      'originalApplicationVersion': '1.0',
      'allExpirationDates': {'premium_monthly': '2027-09-01T00:00:00Z'},
      'allPurchaseDates': {'premium_monthly': '2026-09-01T00:00:00Z'},
      'managementURL': null,
    });

    fakeListener.emit(premiumCustomerInfo);

    final updated = container.read(subscriptionNotifierProvider).value;
    expect(updated?.status, equals(SubscriptionStatus.premium));
    expect(updated?.entitlementId, equals('premium'));
    expect(updated?.willRenew, isTrue);

    // Disposing container triggers onDispose and unregisters listener
    container.dispose();
    expect(fakeListener.listeners.isEmpty, isTrue);
  });
}

class _FakeCustomerInfoListener implements CustomerInfoListener {
  final List<void Function(CustomerInfo)> listeners = [];

  @override
  void add(void Function(CustomerInfo customerInfo) listener) {
    listeners.add(listener);
  }

  @override
  void remove(void Function(CustomerInfo customerInfo) listener) {
    listeners.remove(listener);
  }

  void emit(CustomerInfo customerInfo) {
    for (final listener in List.of(listeners)) {
      listener(customerInfo);
    }
  }
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  final SubscriptionEntity _initial;

  _FakeSubscriptionNotifier(this._initial);

  @override
  Future<SubscriptionEntity> build() async {
    return _initial;
  }
}
