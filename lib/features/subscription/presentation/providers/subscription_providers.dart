import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/datasources/subscription_remote_datasource_impl.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/get_available_plans_usecase.dart';
import '../../domain/usecases/get_current_subscription_usecase.dart';
import '../../domain/usecases/purchase_plan_usecase.dart';
import '../../domain/usecases/restore_purchases_usecase.dart';

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
