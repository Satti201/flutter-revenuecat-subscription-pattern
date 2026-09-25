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
  final String planId;

  const PlanNotFoundException(this.planId)
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

class SubscriptionLoadFailedException extends SubscriptionException {
  const SubscriptionLoadFailedException([
    super.message = 'Unable to load subscription status.',
  ]);
}

class PlansLoadFailedException extends SubscriptionException {
  const PlansLoadFailedException([
    super.message = 'Unable to load subscription plans.',
  ]);
}
