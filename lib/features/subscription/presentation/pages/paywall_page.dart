import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_plan_entity.dart';
import '../providers/subscription_providers.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  String? _selectedPlanId;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansNotifierProvider);
    final actionState = ref.watch(subscriptionActionNotifierProvider);

    ref.listen(subscriptionActionNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(subscriptionActionNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upgrade to Premium'),
        centerTitle: true,
      ),
      body: plansAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(plansNotifierProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No subscription plans found in this offering.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(plansNotifierProvider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reload Plans'),
                    ),
                  ],
                ),
              ),
            );
          }

          _selectedPlanId ??= (plans
                  .where((p) => p.period == SubscriptionPeriod.yearly)
                  .firstOrNull ??
              plans.first)
              .id;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 48,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock Full Access',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a subscription plan to unlock premium features and support ongoing development.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _buildFeatureItem(
                        context,
                        Icons.check_circle_outline_rounded,
                        'Unlimited access to all features',
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureItem(
                        context,
                        Icons.bolt_rounded,
                        'Instant synchronization across sessions',
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureItem(
                        context,
                        Icons.support_agent_rounded,
                        'Priority customer assistance',
                      ),
                      const SizedBox(height: 28),
                      ...plans.map(
                        (plan) => _buildPlanCard(
                          context,
                          plan: plan,
                          isSelected: plan.id == _selectedPlanId,
                          onSelect: () {
                            setState(() {
                              _selectedPlanId = plan.id;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: actionState.isPurchasing ||
                                _selectedPlanId == null
                            ? null
                            : () async {
                                final success = await ref
                                    .read(subscriptionActionNotifierProvider
                                        .notifier)
                                    .purchasePlan(_selectedPlanId!);

                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Subscription activated successfully!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: actionState.isPurchasing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Subscribe Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cancel anytime in your store account settings.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required SubscriptionPlanEntity plan,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final theme = Theme.of(context);
    final periodLabel = switch (plan.period) {
      SubscriptionPeriod.monthly => 'Monthly',
      SubscriptionPeriod.yearly => 'Yearly',
      SubscriptionPeriod.lifetime => 'Lifetime',
      SubscriptionPeriod.unknown => 'Standard',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withAlpha(60)
                : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.title.isNotEmpty ? plan.title : periodLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plan.period == SubscriptionPeriod.yearly) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (plan.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                plan.priceText,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
