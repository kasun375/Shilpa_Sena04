import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'info', 'alert', 'promo'
  final DateTime timestamp;
  final String? imageUrl;
  final String? actionUrl;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.imageUrl,
    this.actionUrl,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'info',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }
}
