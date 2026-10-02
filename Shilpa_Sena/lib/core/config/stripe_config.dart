class StripeConfig {
  static const bool useLiveMode = true;
  static const String defaultCurrency = 'lkr';

  static const String livePublishableKey =
      'pk_live_51Ted5APDNJFdc8fiVuKPhOpSNZblzFGXW9FSUEUiOdC5YWgplyJ23EHagAyJqN2GOn3HXl4uMeYXsGhDLOWYFizC00hUBu6tBU';

  static const String liveSecretKey =
      'YOUR_STRIPE_LIVE_SECRET_KEY';

  static const String testPublishableKey =
      'pk_test_51TepX9PiY8ODIKHWGRvzRAbZaXdjdhq1IHHEgXQeUH9xujMbNSX1vunQJ0L3yQP1fh8iRixeQ0ogliT1N2Se3Mdj00qeXx4Fyo';

  static String get publishableKey =>
      useLiveMode ? livePublishableKey : testPublishableKey;

  static String get secretKey => useLiveMode ? liveSecretKey : '';
}
