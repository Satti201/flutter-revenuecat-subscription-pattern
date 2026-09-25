import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:premium_flow/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_plan_entity.dart';
import 'package:premium_flow/features/subscription/domain/exceptions/subscription_exception.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class FakeSubscriptionRemoteDataSource implements SubscriptionRemoteDataSource {
  CustomerInfo? customerInfo;
  Offerings? offerings;
  CustomerInfo? purchaseCustomerInfo;
  CustomerInfo? restoreCustomerInfo;

  Object? getCustomerInfoError;
  Object? getOfferingsError;
  Object? purchaseError;
  Object? restoreError;

  Package? lastPurchasedPackage;

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    if (getCustomerInfoError != null) {
      throw getCustomerInfoError!;
    }
    return customerInfo!;
  }

  @override
  Future<Offerings> getOfferings() async {
    if (getOfferingsError != null) {
      throw getOfferingsError!;
    }
    return offerings!;
  }

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    lastPurchasedPackage = package;
    if (purchaseError != null) {
      throw purchaseError!;
    }
    return purchaseCustomerInfo ?? customerInfo!;
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    if (restoreError != null) {
      throw restoreError!;
    }
    return restoreCustomerInfo ?? customerInfo!;
  }
}

CustomerInfo _createTestCustomerInfo({
  bool isPremium = true,
  DateTime? expiresAt,
}) {
  final expirationString =
      expiresAt?.toIso8601String() ?? '2027-09-01T00:00:00.000Z';

  return CustomerInfo.fromJson({
    'entitlements': {
      'all': isPremium
          ? {
              'premium': {
                'identifier': 'premium',
                'isActive': true,
                'willRenew': true,
                'periodType': 'normal',
                'latestPurchaseDate': '2026-09-01T00:00:00.000Z',
                'originalPurchaseDate': '2026-09-01T00:00:00.000Z',
                'expirationDate': expirationString,
                'store': 'app_store',
                'productIdentifier': 'premium_yearly',
                'isSandbox': true,
                'unsubscribeDetectedAt': null,
                'billingIssueDetectedAt': null,
              }
            }
          : {},
      'active': isPremium
          ? {
              'premium': {
                'identifier': 'premium',
                'isActive': true,
                'willRenew': true,
                'periodType': 'normal',
                'latestPurchaseDate': '2026-09-01T00:00:00.000Z',
                'originalPurchaseDate': '2026-09-01T00:00:00.000Z',
                'expirationDate': expirationString,
                'store': 'app_store',
                'productIdentifier': 'premium_yearly',
                'isSandbox': true,
                'unsubscribeDetectedAt': null,
                'billingIssueDetectedAt': null,
              }
            }
          : {},
    },
    'activeSubscriptions': isPremium ? ['premium_yearly'] : [],
    'allPurchasedProductIdentifiers': isPremium ? ['premium_yearly'] : [],
    'nonSubscriptionTransactions': [],
    'firstSeen': '2026-01-01T00:00:00.000Z',
    'originalAppUserId': 'user_123',
    'requestDate': '2026-09-25T00:00:00.000Z',
    'originalApplicationVersion': '1.0',
    'allExpirationDates':
        isPremium ? {'premium_yearly': expirationString} : {},
    'allPurchaseDates':
        isPremium ? {'premium_yearly': '2026-09-01T00:00:00.000Z'} : {},
    'managementURL': null,
  });
}

Offerings _createTestOfferings({
  bool hasOffering = true,
  bool asCurrent = true,
}) {
  if (!hasOffering) {
    return Offerings.fromJson(const {
      'all': {},
      'current': null,
    });
  }

  final defaultPackages = [
    {
      'identifier': r'$rc_monthly',
      'packageType': 'MONTHLY',
      'product': {
        'identifier': 'premium_monthly',
        'description': 'Full monthly access',
        'title': 'Monthly Plan',
        'price': 4.99,
        'priceString': r'$4.99',
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
    },
    {
      'identifier': r'$rc_annual',
      'packageType': 'ANNUAL',
      'product': {
        'identifier': 'premium_yearly',
        'description': 'Full yearly access',
        'title': 'Yearly Plan',
        'price': 49.99,
        'priceString': r'$49.99',
        'currencyCode': 'USD',
        'introductoryPrice': null,
        'discounts': null,
        'productCategory': 'SUBSCRIPTION',
        'defaultOption': null,
        'subscriptionOptions': null,
        'presentedOfferingIdentifier': 'default',
        'subscriptionPeriod': 'P1Y',
      },
      'presentedOfferingContext': {
        'offeringIdentifier': 'default',
      },
    },
  ];

  final rawOffering = {
    'identifier': 'default',
    'serverDescription': 'Default Offering',
    'metadata': <String, dynamic>{},
    'availablePackages': defaultPackages,
  };

  return Offerings.fromJson({
    'all': {'default': rawOffering},
    'current': asCurrent ? rawOffering : null,
  });
}

void main() {
  late FakeSubscriptionRemoteDataSource fakeDataSource;
  late SubscriptionRepositoryImpl repository;

  setUp(() {
    fakeDataSource = FakeSubscriptionRemoteDataSource();
    repository = SubscriptionRepositoryImpl(fakeDataSource);
  });

  group('SubscriptionRepositoryImpl - getCurrentSubscription', () {
    test('maps CustomerInfo correctly to domain entity', () async {
      fakeDataSource.customerInfo = _createTestCustomerInfo(
        isPremium: true,
        expiresAt: DateTime.parse('2027-09-01T00:00:00.000Z'),
      );

      final subscription = await repository.getCurrentSubscription();

      expect(subscription.status, equals(SubscriptionStatus.premium));
      expect(subscription.isPremium, isTrue);
      expect(subscription.entitlementId, equals('premium'));
      expect(subscription.willRenew, isTrue);
      expect(
        subscription.expiresAt,
        equals(DateTime.parse('2027-09-01T00:00:00.000Z')),
      );
    });

    test(
        'maps PlatformException to SubscriptionLoadFailedException on failure',
        () async {
      fakeDataSource.getCustomerInfoError = PlatformException(
        code: 'NETWORK_ERROR',
        message: 'Network connection failed',
      );

      expect(
        () => repository.getCurrentSubscription(),
        throwsA(
          isA<SubscriptionLoadFailedException>().having(
            (e) => e.message,
            'message',
            contains('Network connection failed'),
          ),
        ),
      );
    });
  });

  group('SubscriptionRepositoryImpl - getAvailablePlans', () {
    test('maps packages correctly to domain subscription plans', () async {
      fakeDataSource.offerings = _createTestOfferings();

      final plans = await repository.getAvailablePlans();

      expect(plans.length, equals(2));

      final monthlyPlan = plans.first;
      expect(monthlyPlan.id, equals(r'$rc_monthly'));
      expect(monthlyPlan.title, equals('Monthly Plan'));
      expect(monthlyPlan.description, equals('Full monthly access'));
      expect(monthlyPlan.priceText, equals(r'$4.99'));
      expect(monthlyPlan.period, equals(SubscriptionPeriod.monthly));

      final yearlyPlan = plans[1];
      expect(yearlyPlan.id, equals(r'$rc_annual'));
      expect(yearlyPlan.title, equals('Yearly Plan'));
      expect(yearlyPlan.priceText, equals(r'$49.99'));
      expect(yearlyPlan.period, equals(SubscriptionPeriod.yearly));
    });

    test(
        'throws OfferingNotFoundException when current and default offerings are missing',
        () async {
      fakeDataSource.offerings = _createTestOfferings(hasOffering: false);

      expect(
        () => repository.getAvailablePlans(),
        throwsA(isA<OfferingNotFoundException>()),
      );
    });

    test(
        'maps PlatformException to PlansLoadFailedException when fetching offerings fails',
        () async {
      fakeDataSource.getOfferingsError = PlatformException(
        code: 'OFFERINGS_ERROR',
        message: 'Could not fetch offerings from server',
      );

      expect(
        () => repository.getAvailablePlans(),
        throwsA(
          isA<PlansLoadFailedException>().having(
            (e) => e.message,
            'message',
            contains('Could not fetch offerings from server'),
          ),
        ),
      );
    });
  });

  group('SubscriptionRepositoryImpl - purchasePlan', () {
    test(
        'throws OfferingNotFoundException when offerings are missing during purchase',
        () async {
      fakeDataSource.offerings = _createTestOfferings(hasOffering: false);

      expect(
        () => repository.purchasePlan(r'$rc_monthly'),
        throwsA(isA<OfferingNotFoundException>()),
      );
    });

    test('throws PlanNotFoundException when plan identifier does not match',
        () async {
      fakeDataSource.offerings = _createTestOfferings();

      expect(
        () => repository.purchasePlan('non_existent_plan_id'),
        throwsA(
          isA<PlanNotFoundException>().having(
            (e) => e.planId,
            'planId',
            equals('non_existent_plan_id'),
          ),
        ),
      );
    });

    test('returns mapped premium SubscriptionEntity on purchase success',
        () async {
      fakeDataSource.offerings = _createTestOfferings();
      fakeDataSource.purchaseCustomerInfo = _createTestCustomerInfo(
        isPremium: true,
        expiresAt: DateTime.parse('2027-09-01T00:00:00.000Z'),
      );

      final subscription = await repository.purchasePlan(r'$rc_monthly');

      expect(subscription.status, equals(SubscriptionStatus.premium));
      expect(subscription.isPremium, isTrue);
      expect(subscription.entitlementId, equals('premium'));
      expect(fakeDataSource.lastPurchasedPackage?.identifier,
          equals(r'$rc_monthly'));
    });

    test('returns mapped free SubscriptionEntity when purchase has no entitlement',
        () async {
      fakeDataSource.offerings = _createTestOfferings();
      fakeDataSource.purchaseCustomerInfo = _createTestCustomerInfo(
        isPremium: false,
      );

      final subscription = await repository.purchasePlan(r'$rc_monthly');

      expect(subscription.status, equals(SubscriptionStatus.free));
      expect(subscription.isPremium, isFalse);
      expect(subscription.entitlementId, isNull);
    });

    test(
        'maps PlatformException cancellation to PurchaseCancelledException',
        () async {
      fakeDataSource.offerings = _createTestOfferings();
      fakeDataSource.purchaseError = PlatformException(
        code: '${PurchasesErrorCode.purchaseCancelledError.index}',
        message: 'Purchase was cancelled by user',
      );

      expect(
        () => repository.purchasePlan(r'$rc_monthly'),
        throwsA(isA<PurchaseCancelledException>()),
      );
    });

    test('maps other PlatformException to PurchaseFailedException', () async {
      fakeDataSource.offerings = _createTestOfferings();
      fakeDataSource.purchaseError = PlatformException(
        code: '${PurchasesErrorCode.storeProblemError.index}',
        message: 'Store problem occurred',
      );

      expect(
        () => repository.purchasePlan(r'$rc_monthly'),
        throwsA(
          isA<PurchaseFailedException>().having(
            (e) => e.message,
            'message',
            contains('Store problem occurred'),
          ),
        ),
      );
    });
  });

  group('SubscriptionRepositoryImpl - restorePurchases', () {
    test('returns mapped SubscriptionEntity on restore success', () async {
      fakeDataSource.restoreCustomerInfo = _createTestCustomerInfo(
        isPremium: true,
      );

      final subscription = await repository.restorePurchases();

      expect(subscription.status, equals(SubscriptionStatus.premium));
      expect(subscription.isPremium, isTrue);
      expect(subscription.entitlementId, equals('premium'));
    });

    test(
        'maps PlatformException to RestoreFailedException on restore failure',
        () async {
      fakeDataSource.restoreError = PlatformException(
        code: 'RESTORE_ERROR',
        message: 'Restore transactions receipt could not be validated',
      );

      expect(
        () => repository.restorePurchases(),
        throwsA(
          isA<RestoreFailedException>().having(
            (e) => e.message,
            'message',
            contains('Restore transactions receipt could not be validated'),
          ),
        ),
      );
    });
  });
}
