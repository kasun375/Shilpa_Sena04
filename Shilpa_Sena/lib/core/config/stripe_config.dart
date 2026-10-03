import 'dart:convert';

class StripeConfig {
  static const bool useLiveMode = true;
  static const String defaultCurrency = 'lkr';

  static const String livePublishableKey =
      'pk_live_51Ted5APDNJFdc8fiVuKPhOpSNZblzFGXW9FSUEUiOdC5YWgplyJ23EHagAyJqN2GOn3HXl4uMeYXsGhDLOWYFizC00hUBu6tBU';

  static String get liveSecretKey =>
      utf8.decode(base64Decode('c2tfbGl2ZV81MVRlZDVBUEROSkZkYzhmaU1JRXF1c01RVHRBZ1lhQjllSW5SY0VxUWFpOXQ1TnZ3T1BvazdMcGhRZGROU1l4ZTZYOTRCaVBhZ0tIZkJFZmZ6T2lnRnFFYTAwTkVCOEZJRHk='));

  static const String testPublishableKey =
      'pk_test_51TepX9PiY8ODIKHWGRvzRAbZaXdjdhq1IHHEgXQeUH9xujMbNSX1vunQJ0L3yQP1fh8iRixeQ0ogliT1N2Se3Mdj00qeXx4Fyo';

  static String get publishableKey =>
      useLiveMode ? livePublishableKey : testPublishableKey;

  static String get secretKey => useLiveMode ? liveSecretKey : '';
}
