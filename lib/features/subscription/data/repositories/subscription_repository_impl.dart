import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../mappers/subscription_mapper.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl(this.remoteDataSource);

  @override
  Future<SubscriptionEntity> getCurrentSubscription() async {
    final customerInfo = await remoteDataSource.getCustomerInfo();
    return SubscriptionMapper.toSubscriptionEntity(customerInfo);
  }

  @override
  Future<List<SubscriptionPlanEntity>> getAvailablePlans() async {
    final offerings = await remoteDataSource.getOfferings();
    final offering = offerings.current ?? offerings.all['default'];

    if (offering == null) {
      return [];
    }

    return offering.availablePackages
        .map(SubscriptionMapper.toSubscriptionPlanEntity)
        .toList();
  }

  @override
  Future<SubscriptionEntity> purchasePlan(String planId) async {
    final offerings = await remoteDataSource.getOfferings();
    final offering = offerings.current ?? offerings.all['default'];

    if (offering == null) {
      throw Exception('Default offering not found');
    }

    final package = offering.availablePackages
        .where((p) => p.identifier == planId)
        .firstOrNull;

    if (package == null) {
      throw Exception('Subscription plan not found: $planId');
    }

    final customerInfo = await remoteDataSource.purchasePackage(package);
    return SubscriptionMapper.toSubscriptionEntity(customerInfo);
  }

  @override
  Future<SubscriptionEntity> restorePurchases() async {
    final customerInfo = await remoteDataSource.restorePurchases();
    return SubscriptionMapper.toSubscriptionEntity(customerInfo);
  }
}
