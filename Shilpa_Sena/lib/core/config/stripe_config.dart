class StripeConfig {
  // Toggle between Sandbox (Test mode) and Live mode
  static const bool useLiveMode = true;

  // Sandbox / Test Keys (Stripe Sandbox Mode)
  static const String testPublishableKey = 'pk_test_51TepX9PiY8ODIKHWGRvzRAbZaXdjdhq1IHHEgXQeUH9xujMbNSX1vunQJ0L3yQP1fh8iRixeQ0ogliT1N2Se3Mdj00qeXx4Fyo';
  static const String testSecretKey = 'YOUR_STRIPE_TEST_SECRET_KEY';

  // Production / Live Keys (Stripe Live Mode)
  static const String livePublishableKey = 'pk_live_51Ted5APDNJFdc8fiVuKPhOpSNZblzFGXW9FSUEUiOdC5YWgplyJ23EHagAyJqN2GOn3HXl4uMeYXsGhDLOWYFizC00hUBu6tBU';
  static const String liveSecretKey = String.fromEnvironment('STRIPE_LIVE_SECRET_KEY', defaultValue: 'YOUR_STRIPE_LIVE_SECRET_KEY');

  // Dynamic getters returning keys depending on active environment
  static String get publishableKey => useLiveMode ? livePublishableKey : testPublishableKey;
  static String get secretKey => useLiveMode ? liveSecretKey : testSecretKey;
  
  // Default currency for payments
  static const String defaultCurrency = 'lkr';
}
