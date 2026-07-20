import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String title;
  final String date;
  final String time;
  final String zoomLink;
  final bool isAvailable;
  final double price;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.zoomLink,
    this.isAvailable = true,
    this.price = 10.0,
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      zoomLink: data['zoomLink'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      price: (data['price'] as num?)?.toDouble() ?? 10.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'zoomLink': zoomLink,
      'isAvailable': isAvailable,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
