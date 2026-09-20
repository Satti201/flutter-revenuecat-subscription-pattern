enum SubscriptionPeriod {
  monthly,
  yearly,
  lifetime,
  unknown,
}

class SubscriptionPlanEntity {
  final String id;
  final String title;
  final String description;
  final String priceText;
  final SubscriptionPeriod period;

  const SubscriptionPlanEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.priceText,
    required this.period,
  });
}
