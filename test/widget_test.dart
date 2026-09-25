import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_plan_entity.dart';
import 'package:premium_flow/features/subscription/presentation/notifiers/plans_notifier.dart';
import 'package:premium_flow/features/subscription/presentation/notifiers/subscription_action_notifier.dart';
import 'package:premium_flow/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:premium_flow/features/subscription/presentation/pages/home_page.dart';
import 'package:premium_flow/features/subscription/presentation/pages/paywall_page.dart';
import 'package:premium_flow/features/subscription/presentation/pages/subscription_settings_page.dart';
import 'package:premium_flow/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  testWidgets('HomePage displays FREE tier when subscription is free',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionNotifierProvider.overrideWith(
            () => _FakeSubscriptionNotifier(const SubscriptionEntity.free()),
          ),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('PremiumFlow'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Free Tier'), findsOneWidget);
    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('Refresh Status'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('HomePage displays PREMIUM details when subscription is active',
      (WidgetTester tester) async {
    final premiumSubscription = SubscriptionEntity(
      status: SubscriptionStatus.premium,
      entitlementId: 'premium',
      expiresAt: DateTime(2027, 1, 1),
      willRenew: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionNotifierProvider.overrideWith(
            () => _FakeSubscriptionNotifier(premiumSubscription),
          ),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('PREMIUM'), findsOneWidget);
    expect(find.text('Premium Active'), findsOneWidget);
    expect(find.text('Entitlement'), findsOneWidget);
    expect(find.text('premium'), findsOneWidget);
    expect(find.text('Auto-renews'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('View Subscription Details'), findsOneWidget);
  });

  testWidgets('HomePage navigates to PaywallPage for free user CTA',
      (WidgetTester tester) async {
    final samplePlans = [
      const SubscriptionPlanEntity(
        id: r'$rc_monthly',
        title: 'Monthly Subscription',
        description: 'Standard monthly billing',
        priceText: r'$4.99',
        period: SubscriptionPeriod.monthly,
      ),
      const SubscriptionPlanEntity(
        id: r'$rc_annual',
        title: 'Annual Subscription',
        description: 'Save 30% billed yearly',
        priceText: r'$39.99',
        period: SubscriptionPeriod.yearly,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionNotifierProvider.overrideWith(
            () => _FakeSubscriptionNotifier(const SubscriptionEntity.free()),
          ),
          plansNotifierProvider.overrideWith(
            () => _FakePlansNotifier(samplePlans),
          ),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    await tester.pump();

    // Tap 'Upgrade to Premium'
    await tester.tap(find.text('Upgrade to Premium'));
    await tester.pumpAndSettle();

    // Verify Paywall is displayed
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(find.text('Unlock Full Access'), findsOneWidget);
    expect(find.text('Monthly Subscription'), findsOneWidget);
    expect(find.text(r'$4.99'), findsOneWidget);
    expect(find.text('Annual Subscription'), findsOneWidget);
    expect(find.text(r'$39.99'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.text('Subscribe Now'), findsOneWidget);
  });

  testWidgets(
      'HomePage navigates to SubscriptionSettingsPage via AppBar settings icon for Free user',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionNotifierProvider.overrideWith(
            () => _FakeSubscriptionNotifier(const SubscriptionEntity.free()),
          ),
          subscriptionActionNotifierProvider.overrideWith(
            () => _FakeSubscriptionActionNotifier(restoreSuccess: true),
          ),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    await tester.pump();

    // Tap settings icon in AppBar
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SubscriptionSettingsPage), findsOneWidget);
    expect(find.text('Subscription Status'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Free Access'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);

    // Tap 'Restore Purchases'
    await tester.tap(find.text('Restore Purchases'));
    await tester.pumpAndSettle();

    // Feedback indicates no active subscription found since user remains Free
    expect(
      find.text('Restore completed, but no active subscription was found.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'HomePage navigates to SubscriptionSettingsPage via CTA for Premium user and handles Restore',
      (WidgetTester tester) async {
    final premiumSubscription = SubscriptionEntity(
      status: SubscriptionStatus.premium,
      entitlementId: 'premium',
      expiresAt: DateTime(2027, 6, 15),
      willRenew: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionNotifierProvider.overrideWith(
            () => _FakeSubscriptionNotifier(premiumSubscription),
          ),
          subscriptionActionNotifierProvider.overrideWith(
            () => _FakeSubscriptionActionNotifier(restoreSuccess: true),
          ),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    await tester.pump();

    // Tap 'View Subscription Details'
    await tester.tap(find.text('View Subscription Details'));
    await tester.pumpAndSettle();

    expect(find.byType(SubscriptionSettingsPage), findsOneWidget);
    expect(find.text('Subscription Status'), findsOneWidget);
    expect(find.text('PREMIUM'), findsOneWidget);
    expect(find.text('Active Premium'), findsOneWidget);
    expect(find.text('Entitlement'), findsOneWidget);
    expect(find.text('premium'), findsOneWidget);
    expect(find.text('Auto-renews'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('Expires'), findsOneWidget);

    // Tap 'Restore Purchases'
    await tester.tap(find.text('Restore Purchases'));
    await tester.pumpAndSettle();

    expect(find.text('Premium subscription restored.'), findsOneWidget);
  });
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  final SubscriptionEntity _initial;

  _FakeSubscriptionNotifier(this._initial);

  @override
  Future<SubscriptionEntity> build() async {
    return _initial;
  }
}

class _FakePlansNotifier extends PlansNotifier {
  final List<SubscriptionPlanEntity> _plans;

  _FakePlansNotifier(this._plans);

  @override
  Future<List<SubscriptionPlanEntity>> build() async {
    return _plans;
  }
}

class _FakeSubscriptionActionNotifier extends SubscriptionActionNotifier {
  final bool _restoreSuccess;

  _FakeSubscriptionActionNotifier({bool restoreSuccess = true})
      : _restoreSuccess = restoreSuccess;

  @override
  Future<bool> restorePurchases() async {
    return _restoreSuccess;
  }
}
