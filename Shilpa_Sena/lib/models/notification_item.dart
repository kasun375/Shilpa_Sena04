import 'dart:convert';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: map['isRead'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationItem.fromJson(String source) => NotificationItem.fromMap(json.decode(source));
}
