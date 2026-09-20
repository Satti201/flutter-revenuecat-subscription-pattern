class RevenueCatConfig {
  static const String apiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
  );

  static void validate() {
    if (apiKey.isEmpty) {
      throw StateError(
        'REVENUECAT_API_KEY is missing. '
        'Run the app with --dart-define=REVENUECAT_API_KEY=your_key',
      );
    }
  }
}
