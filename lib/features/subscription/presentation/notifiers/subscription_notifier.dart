import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_entity.dart';
import '../providers/subscription_providers.dart';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionEntity> {
  @override
  Future<SubscriptionEntity> build() {
    final useCase = ref.watch(getCurrentSubscriptionUseCaseProvider);
    return useCase();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      final useCase = ref.read(getCurrentSubscriptionUseCaseProvider);
      return useCase();
    });
  }

  void setSubscription(SubscriptionEntity subscription) {
    state = AsyncData(subscription);
  }
}
