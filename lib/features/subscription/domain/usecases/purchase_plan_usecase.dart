import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class PurchasePlanUseCase {
  final SubscriptionRepository repository;

  PurchasePlanUseCase(this.repository);

  Future<SubscriptionEntity> call(String planId) {
    return repository.purchasePlan(planId);
  }
}
