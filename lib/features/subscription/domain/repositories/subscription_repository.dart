import '../entities/subscription_entity.dart';
import '../entities/subscription_plan_entity.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionEntity> getCurrentSubscription();

  Future<List<SubscriptionPlanEntity>> getAvailablePlans();

  Future<SubscriptionEntity> purchasePlan(String planId);

  Future<SubscriptionEntity> restorePurchases();
}
