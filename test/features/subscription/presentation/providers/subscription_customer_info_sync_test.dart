import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/data/listeners/subscription_updates_listener.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:premium_flow/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  test(
      'subscriptionCustomerInfoSyncProvider updates subscription state when listener emits SubscriptionEntity',
      () async {
    final fakeListener = _FakeSubscriptionUpdatesListener();

    final container = ProviderContainer(
      overrides: [
        subscriptionUpdatesListenerProvider.overrideWithValue(fakeListener),
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

    // Simulate listener emitting updated domain SubscriptionEntity
    final premiumSubscription = SubscriptionEntity(
      status: SubscriptionStatus.premium,
      entitlementId: 'premium',
      expiresAt: DateTime(2027, 9, 1),
      willRenew: true,
    );

    fakeListener.emit(premiumSubscription);

    final updated = container.read(subscriptionNotifierProvider).value;
    expect(updated?.status, equals(SubscriptionStatus.premium));
    expect(updated?.entitlementId, equals('premium'));
    expect(updated?.willRenew, isTrue);

    // Disposing container triggers onDispose and unregisters listener
    container.dispose();
    expect(fakeListener.listeners.isEmpty, isTrue);
  });
}

class _FakeSubscriptionUpdatesListener implements SubscriptionUpdatesListener {
  final List<void Function(SubscriptionEntity)> listeners = [];

  @override
  void add(void Function(SubscriptionEntity subscription) listener) {
    listeners.add(listener);
  }

  @override
  void remove(void Function(SubscriptionEntity subscription) listener) {
    listeners.remove(listener);
  }

  void emit(SubscriptionEntity subscription) {
    for (final listener in List.of(listeners)) {
      listener(subscription);
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
