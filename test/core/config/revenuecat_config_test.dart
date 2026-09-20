import 'package:flutter_test/flutter_test.dart';
import 'package:premium_flow/core/config/revenuecat_config.dart';

void main() {
  group('RevenueCatConfig', () {
    test('throws StateError when REVENUECAT_API_KEY is not defined', () {
      expect(
        () => RevenueCatConfig.validate(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('REVENUECAT_API_KEY is missing'),
          ),
        ),
      );
    });
  });
}
