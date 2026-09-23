import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenSecurityService {
  static const MethodChannel _channel =
      MethodChannel('com.shilpasena.lms/security');

  /// Enables FLAG_SECURE to block screenshots & screen recording
  static Future<void> enableSecure() async {
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (e) {
      debugPrint('ScreenSecurityService enableSecure error: $e');
    }
  }

  /// Clears FLAG_SECURE when exiting sensitive screen
  static Future<void> disableSecure() async {
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (e) {
      debugPrint('ScreenSecurityService disableSecure error: $e');
    }
  }
}
