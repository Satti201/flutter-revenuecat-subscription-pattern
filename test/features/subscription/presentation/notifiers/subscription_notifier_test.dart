import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/domain/exceptions/subscription_exception.dart';
import 'package:premium_flow/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:premium_flow/features/subscription/domain/usecases/get_current_subscription_usecase.dart';
import 'package:premium_flow/features/subscription/presentation/providers/subscription_providers.dart';

class FakeGetCurrentSubscriptionUseCase
    implements GetCurrentSubscriptionUseCase {
  @override
  SubscriptionRepository get repository => throw UnimplementedError();

  Future<SubscriptionEntity> Function()? onCall;

  @override
  Future<SubscriptionEntity> call() async {
    if (onCall != null) {
      return onCall!();
    }
    return const SubscriptionEntity.free();
  }
}

void main() {
  late FakeGetCurrentSubscriptionUseCase fakeUseCase;
  late ProviderContainer container;

  setUp(() {
    fakeUseCase = FakeGetCurrentSubscriptionUseCase();
    container = ProviderContainer(
      overrides: [
        getCurrentSubscriptionUseCaseProvider.overrideWithValue(fakeUseCase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial build() loads current subscription from use case', () async {
    fakeUseCase.onCall = () async => const SubscriptionEntity.free();

    final initialSubscription =
        await container.read(subscriptionNotifierProvider.future);

    expect(initialSubscription.status, equals(SubscriptionStatus.free));
    expect(initialSubscription.isPremium, isFalse);
    expect(
      container.read(subscriptionNotifierProvider),
      equals(const AsyncData(SubscriptionEntity.free())),
    );
  });

  test('successful refresh() replaces current state with fresh data', () async {
    fakeUseCase.onCall = () async => const SubscriptionEntity.free();
    await container.read(subscriptionNotifierProvider.future);

    final premium = SubscriptionEntity(
      status: SubscriptionStatus.premium,
      entitlementId: 'premium',
      willRenew: true,
      expiresAt: DateTime.parse('2027-09-01T00:00:00.000Z'),
    );
    fakeUseCase.onCall = () async => premium;

    await container.read(subscriptionNotifierProvider.notifier).refresh();

    final state = container.read(subscriptionNotifierProvider);
    expect(state, isA<AsyncData<SubscriptionEntity>>());
    expect(state.value, equals(premium));
    expect(state.value?.isPremium, isTrue);
  });

  test('failed refresh() transitions state to AsyncError', () async {
    fakeUseCase.onCall = () async => const SubscriptionEntity.free();
    await container.read(subscriptionNotifierProvider.future);

    fakeUseCase.onCall = () => throw const SubscriptionLoadFailedException(
          'Failed to connect to billing service',
        );

    await container.read(subscriptionNotifierProvider.notifier).refresh();

    final state = container.read(subscriptionNotifierProvider);
    expect(state, isA<AsyncError<SubscriptionEntity>>());
    expect(state.error, isA<SubscriptionLoadFailedException>());
    expect(
      (state.error as SubscriptionLoadFailedException).message,
      equals('Failed to connect to billing service'),
    );
  });

  test('setSubscription() immediately replaces state without invoking use case',
      () async {
    fakeUseCase.onCall = () async => const SubscriptionEntity.free();
    await container.read(subscriptionNotifierProvider.future);

    final premium = SubscriptionEntity(
      status: SubscriptionStatus.premium,
      entitlementId: 'premium',
      willRenew: true,
      expiresAt: DateTime.parse('2027-09-01T00:00:00.000Z'),
    );

    // Replace use case with a throwing function to verify it's never invoked
    fakeUseCase.onCall = () => throw StateError('Should not be called');

    container
        .read(subscriptionNotifierProvider.notifier)
        .setSubscription(premium);

    final state = container.read(subscriptionNotifierProvider);
    expect(state, equals(AsyncData(premium)));
    expect(state.value?.isPremium, isTrue);
    expect(state.value?.entitlementId, equals('premium'));
  });
}
