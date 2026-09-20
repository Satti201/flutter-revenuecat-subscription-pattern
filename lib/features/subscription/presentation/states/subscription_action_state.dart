class SubscriptionActionState {
  final bool isPurchasing;
  final bool isRestoring;
  final String? errorMessage;

  const SubscriptionActionState({
    this.isPurchasing = false,
    this.isRestoring = false,
    this.errorMessage,
  });

  SubscriptionActionState copyWith({
    bool? isPurchasing,
    bool? isRestoring,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubscriptionActionState(
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
