import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/data/mappers/subscription_mapper.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_plan_entity.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  group('SubscriptionMapper.toSubscriptionEntity', () {
    test('maps active premium entitlement to SubscriptionEntity.premium', () {
      final customerInfo = CustomerInfo.fromJson(const {
        'entitlements': {
          'all': {
            'premium': {
              'identifier': 'premium',
              'isActive': true,
              'willRenew': true,
              'periodType': 'normal',
              'latestPurchaseDate': '2026-09-01T00:00:00Z',
              'originalPurchaseDate': '2026-09-01T00:00:00Z',
              'expirationDate': '2027-09-01T00:00:00Z',
              'store': 'app_store',
              'productIdentifier': 'premium_yearly',
              'isSandbox': true,
              'unsubscribeDetectedAt': null,
              'billingIssueDetectedAt': null,
            }
          },
          'active': {
            'premium': {
              'identifier': 'premium',
              'isActive': true,
              'willRenew': true,
              'periodType': 'normal',
              'latestPurchaseDate': '2026-09-01T00:00:00Z',
              'originalPurchaseDate': '2026-09-01T00:00:00Z',
              'expirationDate': '2027-09-01T00:00:00Z',
              'store': 'app_store',
              'productIdentifier': 'premium_yearly',
              'isSandbox': true,
              'unsubscribeDetectedAt': null,
              'billingIssueDetectedAt': null,
            }
          },
        },
        'activeSubscriptions': ['premium_yearly'],
        'allPurchasedProductIdentifiers': ['premium_yearly'],
        'nonSubscriptionTransactions': [],
        'firstSeen': '2026-01-01T00:00:00Z',
        'originalAppUserId': 'user_123',
        'requestDate': '2026-09-25T00:00:00Z',
        'originalApplicationVersion': '1.0',
        'allExpirationDates': {'premium_yearly': '2027-09-01T00:00:00Z'},
        'allPurchaseDates': {'premium_yearly': '2026-09-01T00:00:00Z'},
        'managementURL': null,
      });

      final entity = SubscriptionMapper.toSubscriptionEntity(customerInfo);

      expect(entity.status, equals(SubscriptionStatus.premium));
      expect(entity.isPremium, isTrue);
      expect(entity.entitlementId, equals('premium'));
      expect(entity.willRenew, isTrue);
      expect(entity.expiresAt, equals(DateTime.parse('2027-09-01T00:00:00Z')));
    });

    test('maps missing or inactive entitlement to SubscriptionEntity.free()',
        () {
      final customerInfo = CustomerInfo.fromJson(const {
        'entitlements': {
          'all': {
            'premium': {
              'identifier': 'premium',
              'isActive': false,
              'willRenew': false,
              'periodType': 'normal',
              'latestPurchaseDate': '2025-01-01T00:00:00Z',
              'originalPurchaseDate': '2025-01-01T00:00:00Z',
              'expirationDate': '2025-02-01T00:00:00Z',
              'store': 'app_store',
              'productIdentifier': 'premium_monthly',
              'isSandbox': true,
              'unsubscribeDetectedAt': null,
              'billingIssueDetectedAt': null,
            }
          },
          'active': {},
        },
        'activeSubscriptions': [],
        'allPurchasedProductIdentifiers': ['premium_monthly'],
        'nonSubscriptionTransactions': [],
        'firstSeen': '2025-01-01T00:00:00Z',
        'originalAppUserId': 'user_123',
        'requestDate': '2026-09-25T00:00:00Z',
        'originalApplicationVersion': '1.0',
        'allExpirationDates': {'premium_monthly': '2025-02-01T00:00:00Z'},
        'allPurchaseDates': {'premium_monthly': '2025-01-01T00:00:00Z'},
        'managementURL': null,
      });

      final entity = SubscriptionMapper.toSubscriptionEntity(customerInfo);

      expect(entity.status, equals(SubscriptionStatus.free));
      expect(entity.isPremium, isFalse);
      expect(entity.entitlementId, isNull);
      expect(entity.expiresAt, isNull);
      expect(entity.willRenew, isFalse);
    });

    test('handles null and valid expiration dates properly', () {
      // Lifetime / non-expiring entitlement with null expirationDate
      final customerInfoLifetime = CustomerInfo.fromJson(const {
        'entitlements': {
          'all': {
            'premium': {
              'identifier': 'premium',
              'isActive': true,
              'willRenew': false,
              'periodType': 'normal',
              'latestPurchaseDate': '2026-01-01T00:00:00Z',
              'originalPurchaseDate': '2026-01-01T00:00:00Z',
              'expirationDate': null,
              'store': 'app_store',
              'productIdentifier': 'premium_lifetime',
              'isSandbox': true,
              'unsubscribeDetectedAt': null,
              'billingIssueDetectedAt': null,
            }
          },
          'active': {
            'premium': {
              'identifier': 'premium',
              'isActive': true,
              'willRenew': false,
              'periodType': 'normal',
              'latestPurchaseDate': '2026-01-01T00:00:00Z',
              'originalPurchaseDate': '2026-01-01T00:00:00Z',
              'expirationDate': null,
              'store': 'app_store',
              'productIdentifier': 'premium_lifetime',
              'isSandbox': true,
              'unsubscribeDetectedAt': null,
              'billingIssueDetectedAt': null,
            }
          },
        },
        'activeSubscriptions': ['premium_lifetime'],
        'allPurchasedProductIdentifiers': ['premium_lifetime'],
        'nonSubscriptionTransactions': [],
        'firstSeen': '2026-01-01T00:00:00Z',
        'originalAppUserId': 'user_lifetime',
        'requestDate': '2026-09-25T00:00:00Z',
        'originalApplicationVersion': '1.0',
        'allExpirationDates': {},
        'allPurchaseDates': {'premium_lifetime': '2026-01-01T00:00:00Z'},
        'managementURL': null,
      });

      final entity =
          SubscriptionMapper.toSubscriptionEntity(customerInfoLifetime);

      expect(entity.status, equals(SubscriptionStatus.premium));
      expect(entity.isPremium, isTrue);
      expect(entity.expiresAt, isNull);
      expect(entity.willRenew, isFalse);
    });
  });

  group('SubscriptionMapper.toSubscriptionPlanEntity', () {
    test('maps Package fields accurately to SubscriptionPlanEntity', () {
      final package = Package.fromJson(const {
        'identifier': r'$rc_monthly',
        'packageType': 'MONTHLY',
        'product': {
          'identifier': 'premium_monthly',
          'description': 'Full access billed monthly',
          'title': 'Monthly Plan',
          'price': 4.99,
          'priceString': '\$4.99',
          'currencyCode': 'USD',
          'introductoryPrice': null,
          'discounts': null,
          'productCategory': 'SUBSCRIPTION',
          'defaultOption': null,
          'subscriptionOptions': null,
          'presentedOfferingIdentifier': 'default',
          'subscriptionPeriod': 'P1M',
        },
        'presentedOfferingContext': {
          'offeringIdentifier': 'default',
        },
      });

      final plan = SubscriptionMapper.toSubscriptionPlanEntity(package);

      expect(plan.id, equals(r'$rc_monthly'));
      expect(plan.title, equals('Monthly Plan'));
      expect(plan.description, equals('Full access billed monthly'));
      expect(plan.priceText, equals(r'$4.99'));
      expect(plan.period, equals(SubscriptionPeriod.monthly));
    });

    test('maps various PackageType values to appropriate SubscriptionPeriod',
        () {
      Package buildPackageWithType(String packageType) {
        return Package.fromJson({
          'identifier': 'test_pkg',
          'packageType': packageType,
          'product': const {
            'identifier': 'test_prod',
            'description': 'desc',
            'title': 'title',
            'price': 9.99,
            'priceString': '\$9.99',
            'currencyCode': 'USD',
            'introductoryPrice': null,
            'discounts': null,
            'productCategory': 'SUBSCRIPTION',
            'defaultOption': null,
            'subscriptionOptions': null,
            'presentedOfferingIdentifier': 'default',
            'subscriptionPeriod': 'P1M',
          },
          'presentedOfferingContext': const {
            'offeringIdentifier': 'default',
          },
        });
      }

      expect(
        SubscriptionMapper.toSubscriptionPlanEntity(
          buildPackageWithType('ANNUAL'),
        ).period,
        equals(SubscriptionPeriod.yearly),
      );

      expect(
        SubscriptionMapper.toSubscriptionPlanEntity(
          buildPackageWithType('MONTHLY'),
        ).period,
        equals(SubscriptionPeriod.monthly),
      );

      expect(
        SubscriptionMapper.toSubscriptionPlanEntity(
          buildPackageWithType('LIFETIME'),
        ).period,
        equals(SubscriptionPeriod.lifetime),
      );

      expect(
        SubscriptionMapper.toSubscriptionPlanEntity(
          buildPackageWithType('WEEKLY'),
        ).period,
        equals(SubscriptionPeriod.unknown),
      );

      expect(
        SubscriptionMapper.toSubscriptionPlanEntity(
          buildPackageWithType('SIX_MONTH'),
        ).period,
        equals(SubscriptionPeriod.unknown),
      );

      expect(
        SubscriptionMapper.toSubscriptionPlanEntity(
          buildPackageWithType('UNKNOWN'),
        ).period,
        equals(SubscriptionPeriod.unknown),
      );
    });
  });
}
