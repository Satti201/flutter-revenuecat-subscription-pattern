import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/exceptions/subscription_exception.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../mappers/subscription_mapper.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl(this.remoteDataSource);

  @override
  Future<SubscriptionEntity> getCurrentSubscription() async {
    try {
      final customerInfo = await remoteDataSource.getCustomerInfo();
      return SubscriptionMapper.toSubscriptionEntity(customerInfo);
    } on PlatformException catch (e) {
      throw SubscriptionLoadFailedException(
        e.message ?? 'Unable to load subscription status.',
      );
    }
  }

  @override
  Future<List<SubscriptionPlanEntity>> getAvailablePlans() async {
    try {
      final offerings = await remoteDataSource.getOfferings();
      final offering = offerings.current ?? offerings.all['default'];

      if (offering == null) {
        throw const OfferingNotFoundException();
      }

      return offering.availablePackages
          .map(SubscriptionMapper.toSubscriptionPlanEntity)
          .toList();
    } on OfferingNotFoundException {
      rethrow;
    } on PlatformException catch (e) {
      throw PlansLoadFailedException(
        e.message ?? 'Unable to load subscription plans.',
      );
    }
  }

  @override
  Future<SubscriptionEntity> purchasePlan(String planId) async {
    try {
      final offerings = await remoteDataSource.getOfferings();
      final offering = offerings.current ?? offerings.all['default'];

      if (offering == null) {
        throw const OfferingNotFoundException();
      }

      final package = offering.availablePackages
          .where((p) => p.identifier == planId)
          .firstOrNull;

      if (package == null) {
        throw PlanNotFoundException(planId);
      }

      final customerInfo = await remoteDataSource.purchasePackage(package);
      return SubscriptionMapper.toSubscriptionEntity(customerInfo);
    } on SubscriptionException {
      rethrow;
    } on PlatformException catch (e) {
      PurchasesErrorCode? errorCode;
      try {
        errorCode = PurchasesErrorHelper.getErrorCode(e);
      } catch (_) {
        errorCode = null;
      }

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }

      throw PurchaseFailedException(e.message ?? 'Purchase failed.');
    }
  }

  @override
  Future<SubscriptionEntity> restorePurchases() async {
    try {
      final customerInfo = await remoteDataSource.restorePurchases();
      return SubscriptionMapper.toSubscriptionEntity(customerInfo);
    } on PlatformException catch (e) {
      throw RestoreFailedException(
        e.message ?? 'Restore purchases failed.',
      );
    }
  }
}
