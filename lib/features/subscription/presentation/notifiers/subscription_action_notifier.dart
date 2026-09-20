import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exceptions/subscription_exception.dart';
import '../providers/subscription_providers.dart';
import '../states/subscription_action_state.dart';

class SubscriptionActionNotifier
    extends Notifier<SubscriptionActionState> {
  @override
  SubscriptionActionState build() {
    return const SubscriptionActionState();
  }

  Future<bool> purchasePlan(String planId) async {
    if (state.isPurchasing || state.isRestoring) {
      return false;
    }

    state = state.copyWith(
      isPurchasing: true,
      clearError: true,
    );

    try {
      final useCase = ref.read(purchasePlanUseCaseProvider);

      final subscription = await useCase(planId);

      ref
          .read(subscriptionNotifierProvider.notifier)
          .setSubscription(subscription);

      state = state.copyWith(
        isPurchasing: false,
        clearError: true,
      );

      return true;
    } on SubscriptionException catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: e.message,
      );

      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (state.isPurchasing || state.isRestoring) {
      return false;
    }

    state = state.copyWith(
      isRestoring: true,
      clearError: true,
    );

    try {
      final useCase = ref.read(restorePurchasesUseCaseProvider);

      final subscription = await useCase();

      ref
          .read(subscriptionNotifierProvider.notifier)
          .setSubscription(subscription);

      state = state.copyWith(
        isRestoring: false,
        clearError: true,
      );

      return true;
    } on SubscriptionException catch (e) {
      state = state.copyWith(
        isRestoring: false,
        errorMessage: e.message,
      );

      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
