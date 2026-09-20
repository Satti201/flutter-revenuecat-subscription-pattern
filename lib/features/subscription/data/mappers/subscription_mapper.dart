import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';

class SubscriptionMapper {
  static const String premiumEntitlementId = 'premium';

  /// Maps RevenueCat [CustomerInfo] to domain [SubscriptionEntity].
  static SubscriptionEntity toSubscriptionEntity(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.active[premiumEntitlementId];

    if (entitlement != null && entitlement.isActive) {
      return SubscriptionEntity(
        status: SubscriptionStatus.premium,
        entitlementId: entitlement.identifier,
        expiresAt: entitlement.expirationDate != null
            ? DateTime.tryParse(entitlement.expirationDate!)
            : null,
        willRenew: entitlement.willRenew,
      );
    }

    return const SubscriptionEntity.free();
  }

  /// Maps RevenueCat [Package] to domain [SubscriptionPlanEntity].
  static SubscriptionPlanEntity toSubscriptionPlanEntity(Package package) {
    final product = package.storeProduct;

    return SubscriptionPlanEntity(
      id: package.identifier,
      title: product.title,
      description: product.description,
      priceText: product.priceString,
      period: _mapPackageTypeToPeriod(package.packageType),
    );
  }

  static SubscriptionPeriod _mapPackageTypeToPeriod(PackageType packageType) {
    switch (packageType) {
      case PackageType.monthly:
        return SubscriptionPeriod.monthly;
      case PackageType.annual:
        return SubscriptionPeriod.yearly;
      case PackageType.lifetime:
        return SubscriptionPeriod.lifetime;
      case PackageType.unknown:
      case PackageType.custom:
      case PackageType.weekly:
      case PackageType.twoMonth:
      case PackageType.threeMonth:
      case PackageType.sixMonth:
        return SubscriptionPeriod.unknown;
    }
  }
}
