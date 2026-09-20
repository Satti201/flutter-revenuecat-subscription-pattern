import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class GetCurrentSubscriptionUseCase {
  final SubscriptionRepository repository;

  GetCurrentSubscriptionUseCase(this.repository);

  Future<SubscriptionEntity> call() {
    return repository.getCurrentSubscription();
  }
}
