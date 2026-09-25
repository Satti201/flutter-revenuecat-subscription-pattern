import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/datasources/subscription_remote_datasource_impl.dart';
import '../../data/listeners/customer_info_listener.dart';
import '../../data/listeners/revenuecat_customer_info_listener.dart';
import '../../data/mappers/subscription_mapper.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/get_available_plans_usecase.dart';
import '../../domain/usecases/get_current_subscription_usecase.dart';
import '../../domain/usecases/purchase_plan_usecase.dart';
import '../../domain/usecases/restore_purchases_usecase.dart';
import '../notifiers/plans_notifier.dart';
import '../notifiers/subscription_action_notifier.dart';
import '../notifiers/subscription_notifier.dart';
import '../states/subscription_action_state.dart';

final subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
  return SubscriptionRemoteDataSourceImpl();
});

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    ref.watch(subscriptionRemoteDataSourceProvider),
  );
});

final getCurrentSubscriptionUseCaseProvider =
    Provider<GetCurrentSubscriptionUseCase>((ref) {
  return GetCurrentSubscriptionUseCase(
    ref.watch(subscriptionRepositoryProvider),
  );
});

final getAvailablePlansUseCaseProvider =
    Provider<GetAvailablePlansUseCase>((ref) {
  return GetAvailablePlansUseCase(
    ref.watch(subscriptionRepositoryProvider),
  );
});

final purchasePlanUseCaseProvider =
    Provider<PurchasePlanUseCase>((ref) {
  return PurchasePlanUseCase(
    ref.watch(subscriptionRepositoryProvider),
  );
});

final restorePurchasesUseCaseProvider =
    Provider<RestorePurchasesUseCase>((ref) {
  return RestorePurchasesUseCase(
    ref.watch(subscriptionRepositoryProvider),
  );
});

final subscriptionNotifierProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionEntity>(
  SubscriptionNotifier.new,
);

final plansNotifierProvider =
    AsyncNotifierProvider<PlansNotifier, List<SubscriptionPlanEntity>>(
  PlansNotifier.new,
);

final subscriptionActionNotifierProvider =
    NotifierProvider<SubscriptionActionNotifier, SubscriptionActionState>(
  SubscriptionActionNotifier.new,
);

final customerInfoListenerProvider =
    Provider<CustomerInfoListener>((ref) {
  return const RevenueCatCustomerInfoListener();
});

final subscriptionCustomerInfoSyncProvider = Provider<void>((ref) {
  final listenerService = ref.watch(customerInfoListenerProvider);

  void onCustomerInfoUpdated(CustomerInfo customerInfo) {
    final subscription =
        SubscriptionMapper.toSubscriptionEntity(customerInfo);

    ref
        .read(subscriptionNotifierProvider.notifier)
        .setSubscription(subscription);
  }

  listenerService.add(onCustomerInfoUpdated);

  ref.onDispose(() {
    listenerService.remove(onCustomerInfoUpdated);
  });
});
