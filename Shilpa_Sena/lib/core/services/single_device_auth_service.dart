import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SingleDeviceAuthService {
  static final SingleDeviceAuthService _instance =
      SingleDeviceAuthService._internal();
  factory SingleDeviceAuthService() => _instance;
  SingleDeviceAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  Timer? _heartbeatTimer;
  String? _currentDeviceId;

  static const String _deviceIdKey = 'shilpa_sena_device_uuid';

  /// Obtains or generates a persistent unique Device ID for this installation
  Future<String> getDeviceId() async {
    if (_currentDeviceId != null) return _currentDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    _currentDeviceId = deviceId;
    return deviceId;
  }

  /// Registers current device as the single active session for the authenticated user
  Future<bool> registerDeviceSession(String uid) async {
    try {
      final deviceId = await getDeviceId();
      final userRef = _firestore.collection('users').doc(uid);

      final sessionData = {
        'activeDeviceId': deviceId,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid
            ? 'Android'
            : Platform.isIOS
                ? 'iOS'
                : 'Web',
      };

      await userRef.set(sessionData, SetOptions(merge: true));

      // Register session log in subcollection
      await userRef.collection('active_sessions').doc(deviceId).set({
        'deviceId': deviceId,
        'loginTimestamp': FieldValue.serverTimestamp(),
        'lastHeartbeat': FieldValue.serverTimestamp(),
        'isRevoked': false,
      }, SetOptions(merge: true));

      startSessionMonitoring(uid);
      return true;
    } catch (e) {
      debugPrint('Error registering single device session: $e');
      return false;
    }
  }

  /// Listens to Firestore changes to detect if another device logged in
  void startSessionMonitoring(String uid) async {
    final currentDeviceId = await getDeviceId();

    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      final activeDeviceId = data?['activeDeviceId'] as String?;

      if (activeDeviceId != null && activeDeviceId != currentDeviceId) {
        debugPrint(
            'Single Device Violation: Logged in from another device ($activeDeviceId)');
        await handleRemoteSessionInvalidation();
      }
    });

    _startHeartbeat(uid, currentDeviceId);
  }

  /// Heartbeat to update last active timestamp every 2 minutes
  void _startHeartbeat(String uid, String deviceId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      try {
        await _firestore.collection('users').doc(uid).update({
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('active_sessions')
            .doc(deviceId)
            .update({
          'lastHeartbeat': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Heartbeat error: $e');
      }
    });
  }

  /// Handles auto-logout when current device is superseded
  Future<void> handleRemoteSessionInvalidation() async {
    stopSessionMonitoring();
    await _auth.signOut();
  }

  void stopSessionMonitoring() {
    _sessionSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _sessionSubscription = null;
    _heartbeatTimer = null;
  }
}
