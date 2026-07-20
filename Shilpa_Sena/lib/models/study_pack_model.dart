import 'package:cloud_firestore/cloud_firestore.dart';

class StudyPackModel {
  final String id;
  final String title;
  final String driveLink;
  final DateTime createdAt;

  StudyPackModel({
    required this.id,
    required this.title,
    required this.driveLink,
    required this.createdAt,
  });

  factory StudyPackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyPackModel(
      id: doc.id,
      title: data['title'] ?? '',
      driveLink: data['driveLink'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'driveLink': driveLink,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
