import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/features/subscription/domain/entities/subscription_plan_entity.dart';
import 'package:premium_flow/features/subscription/domain/exceptions/subscription_exception.dart';
import 'package:premium_flow/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:premium_flow/features/subscription/domain/usecases/get_available_plans_usecase.dart';
import 'package:premium_flow/features/subscription/presentation/providers/subscription_providers.dart';

class FakeGetAvailablePlansUseCase implements GetAvailablePlansUseCase {
  @override
  SubscriptionRepository get repository => throw UnimplementedError();

  Future<List<SubscriptionPlanEntity>> Function()? onCall;

  @override
  Future<List<SubscriptionPlanEntity>> call() async {
    if (onCall != null) {
      return onCall!();
    }
    return const [];
  }
}

void main() {
  late FakeGetAvailablePlansUseCase fakeUseCase;
  late ProviderContainer container;

  const monthlyPlan = SubscriptionPlanEntity(
    id: r'$rc_monthly',
    title: 'Monthly Plan',
    description: 'Billed monthly',
    priceText: r'$4.99',
    period: SubscriptionPeriod.monthly,
  );

  const yearlyPlan = SubscriptionPlanEntity(
    id: r'$rc_annual',
    title: 'Yearly Plan',
    description: 'Billed annually',
    priceText: r'$49.99',
    period: SubscriptionPeriod.yearly,
  );

  setUp(() {
    fakeUseCase = FakeGetAvailablePlansUseCase();
    container = ProviderContainer(
      overrides: [
        getAvailablePlansUseCaseProvider.overrideWithValue(fakeUseCase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial build() loads available plans from use case', () async {
    fakeUseCase.onCall = () async => [monthlyPlan, yearlyPlan];

    final plans = await container.read(plansNotifierProvider.future);

    expect(plans.length, equals(2));
    expect(plans.first.id, equals(r'$rc_monthly'));
    expect(plans.last.id, equals(r'$rc_annual'));
    final state = container.read(plansNotifierProvider);
    expect(state, isA<AsyncData<List<SubscriptionPlanEntity>>>());
    expect(state.value?.length, equals(2));
    expect(state.value?.first.id, equals(r'$rc_monthly'));
    expect(state.value?.last.id, equals(r'$rc_annual'));
  });

  test('successful refresh() replaces plans with updated data', () async {
    fakeUseCase.onCall = () async => [monthlyPlan];
    await container.read(plansNotifierProvider.future);

    fakeUseCase.onCall = () async => [monthlyPlan, yearlyPlan];

    await container.read(plansNotifierProvider.notifier).refresh();

    final state = container.read(plansNotifierProvider);
    expect(state, isA<AsyncData<List<SubscriptionPlanEntity>>>());
    expect(state.value?.length, equals(2));
    expect(state.value?.last.period, equals(SubscriptionPeriod.yearly));
  });

  test('failed refresh() transitions state to AsyncError', () async {
    fakeUseCase.onCall = () async => [monthlyPlan];
    await container.read(plansNotifierProvider.future);

    fakeUseCase.onCall = () => throw const PlansLoadFailedException(
          'Failed to load offerings from RevenueCat',
        );

    await container.read(plansNotifierProvider.notifier).refresh();

    final state = container.read(plansNotifierProvider);
    expect(state, isA<AsyncError<List<SubscriptionPlanEntity>>>());
    expect(state.error, isA<PlansLoadFailedException>());
    expect(
      (state.error as PlansLoadFailedException).message,
      equals('Failed to load offerings from RevenueCat'),
    );
  });
}
