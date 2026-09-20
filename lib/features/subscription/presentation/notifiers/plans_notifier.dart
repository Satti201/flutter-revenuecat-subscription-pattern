import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_plan_entity.dart';
import '../providers/subscription_providers.dart';

class PlansNotifier
    extends AsyncNotifier<List<SubscriptionPlanEntity>> {
  @override
  Future<List<SubscriptionPlanEntity>> build() {
    final useCase = ref.watch(getAvailablePlansUseCaseProvider);
    return useCase();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      final useCase = ref.read(getAvailablePlansUseCaseProvider);
      return useCase();
    });
  }
}
