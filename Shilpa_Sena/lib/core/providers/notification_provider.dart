import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_notifications';
  
  // Stream to trigger real-time reload across active UI screens
  static final StreamController<void> _refreshStreamController = StreamController<void>.broadcast();

  static void notifyReceived() {
    _refreshStreamController.add(null);
  }
  
  List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
    
    // Listen to real-time notification events in foreground/active screens
    _refreshStreamController.stream.listen((_) {
      reload();
    });
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList(_storageKey);
    
    if (savedList != null) {
      _notifications = savedList.map((str) => NotificationItem.fromJson(str)).toList();
      // Sort by newest first
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> saveNotification(NotificationItem notification) async {
    _notifications.insert(0, notification);
    notifyListeners();
    await _persistNotifications();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _persistNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _persistNotifications();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _persistNotifications();
  }

  Future<void> _persistNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = _notifications.map((n) => n.toJson()).toList();
    await prefs.setStringList(_storageKey, encodedList);
  }

  // Helper to save directly from background isolate without provider instance
  static Future<void> saveMessageLocally(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedList = prefs.getStringList(_storageKey) ?? [];
    
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );

    savedList.insert(0, notification.toJson());
    await prefs.setStringList(_storageKey, savedList);
  }

  // Call this when app resumes to catch any notifications that came in background
  Future<void> reload() async {
    await _loadNotifications();
  }
}

