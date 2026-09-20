abstract class SubscriptionException implements Exception {
  final String message;

  const SubscriptionException(this.message);

  @override
  String toString() => message;
}

class OfferingNotFoundException extends SubscriptionException {
  const OfferingNotFoundException()
      : super('No subscription offering is currently available.');
}

class PlanNotFoundException extends SubscriptionException {
  const PlanNotFoundException(String planId)
      : super('Subscription plan not found: $planId');
}

class PurchaseCancelledException extends SubscriptionException {
  const PurchaseCancelledException()
      : super('Purchase was cancelled.');
}

class PurchaseFailedException extends SubscriptionException {
  const PurchaseFailedException([super.message = 'Purchase failed.']);
}

class RestoreFailedException extends SubscriptionException {
  const RestoreFailedException([super.message = 'Restore purchases failed.']);
}
