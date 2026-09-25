import 'package:purchases_flutter/purchases_flutter.dart';

abstract class CustomerInfoListener {
  void add(void Function(CustomerInfo customerInfo) listener);
  void remove(void Function(CustomerInfo customerInfo) listener);
}
