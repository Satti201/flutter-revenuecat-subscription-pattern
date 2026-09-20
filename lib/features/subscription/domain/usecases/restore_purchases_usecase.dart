import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class RestorePurchasesUseCase {
  final SubscriptionRepository repository;

  RestorePurchasesUseCase(this.repository);

  Future<SubscriptionEntity> call() {
    return repository.restorePurchases();
  }
}
