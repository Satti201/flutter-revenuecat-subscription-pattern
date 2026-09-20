enum SubscriptionStatus {
  free,
  premium,
}

class SubscriptionEntity {
  final SubscriptionStatus status;
  final String? entitlementId;
  final DateTime? expiresAt;
  final bool willRenew;

  const SubscriptionEntity({
    required this.status,
    this.entitlementId,
    this.expiresAt,
    required this.willRenew,
  });

  /// Convenient factory constructor representing a default free user state.
  const SubscriptionEntity.free()
      : status = SubscriptionStatus.free,
        entitlementId = null,
        expiresAt = null,
        willRenew = false;

  bool get isPremium => status == SubscriptionStatus.premium;
}
