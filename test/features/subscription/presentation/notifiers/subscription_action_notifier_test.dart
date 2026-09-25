import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/domain/exceptions/subscription_exception.dart';
import 'package:premium_flow/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:premium_flow/features/subscription/domain/usecases/purchase_plan_usecase.dart';
import 'package:premium_flow/features/subscription/domain/usecases/restore_purchases_usecase.dart';
import 'package:premium_flow/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:premium_flow/features/subscription/presentation/providers/subscription_providers.dart';

class FakePurchasePlanUseCase implements PurchasePlanUseCase {
  @override
  SubscriptionRepository get repository => throw UnimplementedError();

  Future<SubscriptionEntity> Function(String planId)? onCall;
  String? lastPurchasedPlanId;
  int callCount = 0;

  @override
  Future<SubscriptionEntity> call(String planId) async {
    callCount++;
    lastPurchasedPlanId = planId;
    if (onCall != null) {
      return onCall!(planId);
    }
    return const SubscriptionEntity.free();
  }
}

class FakeRestorePurchasesUseCase implements RestorePurchasesUseCase {
  @override
  SubscriptionRepository get repository => throw UnimplementedError();

  Future<SubscriptionEntity> Function()? onCall;
  int callCount = 0;

  @override
  Future<SubscriptionEntity> call() async {
    callCount++;
    if (onCall != null) {
      return onCall!();
    }
    return const SubscriptionEntity.free();
  }
}

class TrackingSubscriptionNotifier extends SubscriptionNotifier {
  SubscriptionEntity? lastUpdatedSubscription;
  int setSubscriptionCallCount = 0;

  @override
  Future<SubscriptionEntity> build() async {
    return const SubscriptionEntity.free();
  }

  @override
  void setSubscription(SubscriptionEntity subscription) {
    lastUpdatedSubscription = subscription;
    setSubscriptionCallCount++;
    super.setSubscription(subscription);
  }
}

void main() {
  late FakePurchasePlanUseCase fakePurchaseUseCase;
  late FakeRestorePurchasesUseCase fakeRestoreUseCase;
  late TrackingSubscriptionNotifier trackingSubscriptionNotifier;
  late ProviderContainer container;

  final premiumSubscription = SubscriptionEntity(
    status: SubscriptionStatus.premium,
    entitlementId: 'premium',
    willRenew: true,
    expiresAt: DateTime.parse('2027-09-01T00:00:00.000Z'),
  );

  setUp(() {
    fakePurchaseUseCase = FakePurchasePlanUseCase();
    fakeRestoreUseCase = FakeRestorePurchasesUseCase();
    trackingSubscriptionNotifier = TrackingSubscriptionNotifier();

    container = ProviderContainer(
      overrides: [
        purchasePlanUseCaseProvider.overrideWithValue(fakePurchaseUseCase),
        restorePurchasesUseCaseProvider.overrideWithValue(fakeRestoreUseCase),
        subscriptionNotifierProvider.overrideWith(
          () => trackingSubscriptionNotifier,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('purchasePlan', () {
    test(
        'purchase success calls usecase, updates subscription notifier, returns true, and resets isPurchasing',
        () async {
      fakePurchaseUseCase.onCall = (planId) async => premiumSubscription;

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      final result = await notifier.purchasePlan(r'$rc_monthly');

      expect(result, isTrue);
      expect(fakePurchaseUseCase.callCount, equals(1));
      expect(fakePurchaseUseCase.lastPurchasedPlanId, equals(r'$rc_monthly'));

      // Verifies subscription notifier was notified
      expect(trackingSubscriptionNotifier.setSubscriptionCallCount, equals(1));
      expect(trackingSubscriptionNotifier.lastUpdatedSubscription,
          equals(premiumSubscription));
      expect(container.read(subscriptionNotifierProvider).value,
          equals(premiumSubscription));

      // Verifies action state
      final actionState = container.read(subscriptionActionNotifierProvider);
      expect(actionState.isPurchasing, isFalse);
      expect(actionState.isRestoring, isFalse);
      expect(actionState.errorMessage, isNull);
    });

    test(
        'purchase failure catches SubscriptionException, stores error, returns false, and resets isPurchasing',
        () async {
      fakePurchaseUseCase.onCall = (planId) => throw const PurchaseFailedException(
            'Card was declined by issuing bank',
          );

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      final result = await notifier.purchasePlan(r'$rc_monthly');

      expect(result, isFalse);
      expect(trackingSubscriptionNotifier.setSubscriptionCallCount, equals(0));

      final actionState = container.read(subscriptionActionNotifierProvider);
      expect(actionState.isPurchasing, isFalse);
      expect(actionState.errorMessage,
          equals('Card was declined by issuing bank'));
    });

    test('purchase cancellation catches PurchaseCancelledException cleanly',
        () async {
      fakePurchaseUseCase.onCall =
          (planId) => throw const PurchaseCancelledException();

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      final result = await notifier.purchasePlan(r'$rc_monthly');

      expect(result, isFalse);
      expect(trackingSubscriptionNotifier.setSubscriptionCallCount, equals(0));

      final actionState = container.read(subscriptionActionNotifierProvider);
      expect(actionState.isPurchasing, isFalse);
      expect(actionState.errorMessage, equals('Purchase was cancelled.'));
    });
  });

  group('restorePurchases', () {
    test(
        'restore success calls usecase, updates subscription notifier, returns true, and resets isRestoring',
        () async {
      fakeRestoreUseCase.onCall = () async => premiumSubscription;

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      final result = await notifier.restorePurchases();

      expect(result, isTrue);
      expect(fakeRestoreUseCase.callCount, equals(1));
      expect(trackingSubscriptionNotifier.setSubscriptionCallCount, equals(1));
      expect(trackingSubscriptionNotifier.lastUpdatedSubscription,
          equals(premiumSubscription));

      final actionState = container.read(subscriptionActionNotifierProvider);
      expect(actionState.isRestoring, isFalse);
      expect(actionState.isPurchasing, isFalse);
      expect(actionState.errorMessage, isNull);
    });

    test(
        'restore failure catches SubscriptionException, stores error, returns false, and resets isRestoring',
        () async {
      fakeRestoreUseCase.onCall = () => throw const RestoreFailedException(
            'No existing purchase receipt found on store account',
          );

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      final result = await notifier.restorePurchases();

      expect(result, isFalse);
      expect(trackingSubscriptionNotifier.setSubscriptionCallCount, equals(0));

      final actionState = container.read(subscriptionActionNotifierProvider);
      expect(actionState.isRestoring, isFalse);
      expect(
        actionState.errorMessage,
        equals('No existing purchase receipt found on store account'),
      );
    });
  });

  group('duplicate action protection', () {
    test('blocks second purchase while purchase is already in progress',
        () async {
      final purchaseCompleter = Completer<SubscriptionEntity>();
      fakePurchaseUseCase.onCall = (planId) => purchaseCompleter.future;

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      // Start first purchase
      final firstPurchaseFuture = notifier.purchasePlan(r'$rc_monthly');
      expect(container.read(subscriptionActionNotifierProvider).isPurchasing,
          isTrue);

      // Attempt duplicate purchase while first is still running
      final duplicatePurchaseResult = await notifier.purchasePlan(r'$rc_annual');
      expect(duplicatePurchaseResult, isFalse);
      expect(fakePurchaseUseCase.callCount, equals(1));

      // Attempt restore while purchase is running
      final blockedRestoreResult = await notifier.restorePurchases();
      expect(blockedRestoreResult, isFalse);
      expect(fakeRestoreUseCase.callCount, equals(0));

      // Resolve first purchase
      purchaseCompleter.complete(premiumSubscription);
      final firstPurchaseResult = await firstPurchaseFuture;

      expect(firstPurchaseResult, isTrue);
      expect(container.read(subscriptionActionNotifierProvider).isPurchasing,
          isFalse);
    });

    test('blocks purchase while restore is already in progress', () async {
      final restoreCompleter = Completer<SubscriptionEntity>();
      fakeRestoreUseCase.onCall = () => restoreCompleter.future;

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      // Start restore
      final restoreFuture = notifier.restorePurchases();
      expect(container.read(subscriptionActionNotifierProvider).isRestoring,
          isTrue);

      // Attempt purchase while restore is in progress
      final blockedPurchaseResult = await notifier.purchasePlan(r'$rc_monthly');
      expect(blockedPurchaseResult, isFalse);
      expect(fakePurchaseUseCase.callCount, equals(0));

      // Attempt duplicate restore while first is still running
      final duplicateRestoreResult = await notifier.restorePurchases();
      expect(duplicateRestoreResult, isFalse);
      expect(fakeRestoreUseCase.callCount, equals(1));

      // Resolve restore
      restoreCompleter.complete(premiumSubscription);
      final restoreResult = await restoreFuture;

      expect(restoreResult, isTrue);
      expect(container.read(subscriptionActionNotifierProvider).isRestoring,
          isFalse);
    });
  });

  group('unexpected exception and finally reset guarantee', () {
    test('resets isPurchasing even when an unexpected Exception is thrown',
        () async {
      fakePurchaseUseCase.onCall =
          (planId) => throw const FormatException('Unexpected runtime parse error');

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      await expectLater(
        () => notifier.purchasePlan(r'$rc_monthly'),
        throwsA(isA<FormatException>()),
      );

      final actionState = container.read(subscriptionActionNotifierProvider);
      expect(actionState.isPurchasing, isFalse);
    });

    test('resets isRestoring even when an unexpected Exception is thrown',
        () async {
      fakeRestoreUseCase.onCall =
          () => throw StateError('Critical unexpected state error');

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      await expectLater(
        () => notifier.restorePurchases(),
        throwsA(isA<StateError>()),
      );

      final actionState = container.read(subscriptionActionNotifierProvider);
      expect(actionState.isRestoring, isFalse);
    });
  });

  group('clearError', () {
    test('clears errorMessage when clearError() is invoked', () async {
      fakePurchaseUseCase.onCall =
          (planId) => throw const PurchaseFailedException('Some purchase error');

      final notifier =
          container.read(subscriptionActionNotifierProvider.notifier);

      await notifier.purchasePlan(r'$rc_monthly');
      expect(
          container.read(subscriptionActionNotifierProvider).errorMessage,
          isNotNull);

      notifier.clearError();

      expect(
          container.read(subscriptionActionNotifierProvider).errorMessage,
          isNull);
    });
  });
}
