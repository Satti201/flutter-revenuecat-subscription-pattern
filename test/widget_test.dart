import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_entity.dart';
import 'package:premium_flow/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:premium_flow/features/subscription/presentation/pages/home_page.dart';
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

    // Initial frame triggers build
    await tester.pump();

    expect(find.text('PremiumFlow'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Free Tier'), findsOneWidget);
    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('Refresh Status'), findsOneWidget);
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
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  final SubscriptionEntity _initial;

  _FakeSubscriptionNotifier(this._initial);

  @override
  Future<SubscriptionEntity> build() async {
    return _initial;
  }
}
