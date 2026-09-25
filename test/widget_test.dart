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
import 'package:premium_flow/features/subscription/presentation/states/subscription_action_state.dart';

void main() {
  const samplePlans = [
    SubscriptionPlanEntity(
      id: r'$rc_monthly',
      title: 'Monthly Subscription',
      description: 'Standard monthly billing',
      priceText: r'$4.99',
      period: SubscriptionPeriod.monthly,
    ),
    SubscriptionPlanEntity(
      id: r'$rc_annual',
      title: 'Annual Subscription',
      description: 'Save 30% billed yearly',
      priceText: r'$39.99',
      period: SubscriptionPeriod.yearly,
    ),
  ];

  group('HomePage Widget Tests', () {
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

      await tester.tap(find.text('Upgrade to Premium'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionSettingsPage), findsOneWidget);
      expect(find.text('Subscription Status'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('Free Access'), findsOneWidget);
      expect(find.text('Restore Purchases'), findsOneWidget);

      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle();

      expect(find.text('Premium subscription restored.'), findsOneWidget);
    });

    testWidgets(
        'HomePage displays error state on failure and retry triggers refresh',
        (WidgetTester tester) async {
      final fakeSubscriptionNotifier = _FakeSubscriptionNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionNotifierProvider.overrideWith(
              () => fakeSubscriptionNotifier,
            ),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pump();

      fakeSubscriptionNotifier.setError('Billing service unavailable');
      await tester.pump();

      expect(find.text('Billing service unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fakeSubscriptionNotifier.refreshCallCount, equals(1));
    });
  });

  group('PaywallPage Widget Tests', () {
    testWidgets(
        'PaywallPage: selecting monthly plan updates target and purchase passes selected plan ID',
        (WidgetTester tester) async {
      final fakeActionNotifier = _FakeSubscriptionActionNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plansNotifierProvider.overrideWith(
              () => _FakePlansNotifier(samplePlans),
            ),
            subscriptionActionNotifierProvider.overrideWith(
              () => fakeActionNotifier,
            ),
          ],
          child: const MaterialApp(
            home: PaywallPage(),
          ),
        ),
      );

      await tester.pump();

      // Tap monthly plan card to switch selection from default annual plan
      await tester.tap(find.text('Monthly Subscription'));
      await tester.pump();

      // Tap 'Subscribe Now'
      await tester.tap(find.text('Subscribe Now'));
      await tester.pump();

      expect(fakeActionNotifier.purchaseCallCount, equals(1));
      expect(fakeActionNotifier.lastPurchasedPlanId, equals(r'$rc_monthly'));
    });

    testWidgets(
        'PaywallPage: purchase loading state shows spinner and disables button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plansNotifierProvider.overrideWith(
              () => _FakePlansNotifier(samplePlans),
            ),
            subscriptionActionNotifierProvider.overrideWith(
              () => _FakeSubscriptionActionNotifier(
                initialState:
                    const SubscriptionActionState(isPurchasing: true),
              ),
            ),
          ],
          child: const MaterialApp(
            home: PaywallPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'PaywallPage: empty plans state displays empty message and reload triggers refresh',
        (WidgetTester tester) async {
      final fakePlansNotifier = _FakePlansNotifier(const []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plansNotifierProvider.overrideWith(
              () => fakePlansNotifier,
            ),
          ],
          child: const MaterialApp(
            home: PaywallPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No subscription plans found in this offering.'),
          findsOneWidget);
      expect(find.text('Reload Plans'), findsOneWidget);

      await tester.tap(find.text('Reload Plans'));
      await tester.pump();

      expect(fakePlansNotifier.refreshCallCount, equals(1));
    });

    testWidgets(
        'PaywallPage: error state displays error message and retry triggers refresh',
        (WidgetTester tester) async {
      final fakePlansNotifier = _FakePlansNotifier(samplePlans);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plansNotifierProvider.overrideWith(
              () => fakePlansNotifier,
            ),
          ],
          child: const MaterialApp(
            home: PaywallPage(),
          ),
        ),
      );

      await tester.pump();

      fakePlansNotifier.setError('Network error fetching plans');
      await tester.pump();

      expect(find.text('Network error fetching plans'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(fakePlansNotifier.refreshCallCount, equals(1));
    });

    testWidgets(
        'PaywallPage: purchase error surfaces in floating SnackBar',
        (WidgetTester tester) async {
      final fakeActionNotifier = _FakeSubscriptionActionNotifier(
        purchaseSuccess: false,
        purchaseErrorMessage: 'Payment declined by bank',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plansNotifierProvider.overrideWith(
              () => _FakePlansNotifier(samplePlans),
            ),
            subscriptionActionNotifierProvider.overrideWith(
              () => fakeActionNotifier,
            ),
          ],
          child: const MaterialApp(
            home: PaywallPage(),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Subscribe Now'));
      await tester.pump();

      expect(find.text('Payment declined by bank'), findsOneWidget);
    });
  });

  group('SubscriptionSettingsPage Widget Tests', () {
    testWidgets(
        'SubscriptionSettingsPage: restore loading displays spinner and disables button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionNotifierProvider.overrideWith(
              () => _FakeSubscriptionNotifier(const SubscriptionEntity.free()),
            ),
            subscriptionActionNotifierProvider.overrideWith(
              () => _FakeSubscriptionActionNotifier(
                initialState: const SubscriptionActionState(isRestoring: true),
              ),
            ),
          ],
          child: const MaterialApp(
            home: SubscriptionSettingsPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final restoreButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(restoreButton.onPressed, isNull);
    });

    testWidgets(
        'SubscriptionSettingsPage: restore failure surfaces in floating SnackBar',
        (WidgetTester tester) async {
      final fakeActionNotifier = _FakeSubscriptionActionNotifier(
        restoreSuccess: false,
        restoreErrorMessage: 'Receipt validation failed',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionNotifierProvider.overrideWith(
              () => _FakeSubscriptionNotifier(const SubscriptionEntity.free()),
            ),
            subscriptionActionNotifierProvider.overrideWith(
              () => fakeActionNotifier,
            ),
          ],
          child: const MaterialApp(
            home: SubscriptionSettingsPage(),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Restore Purchases'));
      await tester.pump();

      expect(find.text('Receipt validation failed'), findsOneWidget);
    });

    testWidgets(
        'SubscriptionSettingsPage: refresh button triggers subscription refresh',
        (WidgetTester tester) async {
      final fakeSubscriptionNotifier =
          _FakeSubscriptionNotifier(const SubscriptionEntity.free());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionNotifierProvider.overrideWith(
              () => fakeSubscriptionNotifier,
            ),
          ],
          child: const MaterialApp(
            home: SubscriptionSettingsPage(),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Refresh Status'));
      await tester.pump();

      expect(fakeSubscriptionNotifier.refreshCallCount, equals(1));
    });
  });
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  final SubscriptionEntity _initial;
  int refreshCallCount = 0;

  _FakeSubscriptionNotifier([this._initial = const SubscriptionEntity.free()]);

  @override
  Future<SubscriptionEntity> build() async {
    return _initial;
  }

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }

  void setError(Object error) {
    state = AsyncError(error, StackTrace.current);
  }
}

class _FakePlansNotifier extends PlansNotifier {
  final List<SubscriptionPlanEntity> _plans;
  int refreshCallCount = 0;

  _FakePlansNotifier([this._plans = const []]);

  @override
  Future<List<SubscriptionPlanEntity>> build() async {
    return _plans;
  }

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }

  void setError(Object error) {
    state = AsyncError(error, StackTrace.current);
  }
}

class _FakeSubscriptionActionNotifier extends SubscriptionActionNotifier {
  final SubscriptionActionState _initialState;
  final bool _purchaseSuccess;
  final bool _restoreSuccess;
  final String? _purchaseErrorMessage;
  final String? _restoreErrorMessage;
  String? lastPurchasedPlanId;
  int purchaseCallCount = 0;
  int restoreCallCount = 0;

  _FakeSubscriptionActionNotifier({
    SubscriptionActionState initialState = const SubscriptionActionState(),
    bool purchaseSuccess = true,
    bool restoreSuccess = true,
    String? purchaseErrorMessage,
    String? restoreErrorMessage,
  })  : _initialState = initialState,
        _purchaseSuccess = purchaseSuccess,
        _restoreSuccess = restoreSuccess,
        _purchaseErrorMessage = purchaseErrorMessage,
        _restoreErrorMessage = restoreErrorMessage;

  @override
  SubscriptionActionState build() {
    return _initialState;
  }

  @override
  Future<bool> purchasePlan(String planId) async {
    purchaseCallCount++;
    lastPurchasedPlanId = planId;
    if (_purchaseErrorMessage != null) {
      state = state.copyWith(errorMessage: _purchaseErrorMessage);
      return false;
    }
    return _purchaseSuccess;
  }

  @override
  Future<bool> restorePurchases() async {
    restoreCallCount++;
    if (_restoreErrorMessage != null) {
      state = state.copyWith(errorMessage: _restoreErrorMessage);
      return false;
    }
    return _restoreSuccess;
  }
}
