import '../entities/subscription_plan_entity.dart';
import '../repositories/subscription_repository.dart';

class GetAvailablePlansUseCase {
  final SubscriptionRepository repository;

  GetAvailablePlansUseCase(this.repository);

  Future<List<SubscriptionPlanEntity>> call() {
    return repository.getAvailablePlans();
  }
}
