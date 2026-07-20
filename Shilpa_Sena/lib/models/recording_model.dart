import 'package:cloud_firestore/cloud_firestore.dart';

class RecordingModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final DateTime uploadedAt;

  RecordingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.uploadedAt,
  });

  factory RecordingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordingModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
    };
  }
}
