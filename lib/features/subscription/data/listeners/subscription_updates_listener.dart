import '../../domain/entities/subscription_entity.dart';

abstract class SubscriptionUpdatesListener {
  void add(void Function(SubscriptionEntity subscription) listener);
  void remove(void Function(SubscriptionEntity subscription) listener);
}
