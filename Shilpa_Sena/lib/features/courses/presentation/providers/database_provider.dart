import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart';
import 'package:exim_graphics_lms/models/course_model.dart';
import 'package:exim_graphics_lms/models/recording_model.dart';
import 'package:exim_graphics_lms/models/study_pack_model.dart';
import 'package:exim_graphics_lms/models/announcement_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseProvider extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;

  List<CourseModel> _myCourses = [];
  List<CourseModel> get myCourses => _myCourses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _promoImageUrls = [];
  List<String> get promoImageUrls => _promoImageUrls;

  List<RecordingModel> _recordings = [];
  List<RecordingModel> get recordings => _recordings;

  List<StudyPackModel> _studyPacks = [];
  List<StudyPackModel> get studyPacks => _studyPacks;

  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> get announcements => _announcements;

  // Initialize and stream courses from Firestore
  void initStreams() {
    firestore.collection('courses').snapshots().listen((snapshot) {
      _courses = snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
      // Refresh myCourses whenever the courses list changes
      fetchMyCourses();
      notifyListeners();
    }, onError: (error) => debugPrint('Error fetching courses: $error'));

    firestore.collection('promos').snapshots().listen((snapshot) {
      _promoImageUrls = snapshot.docs
          .map((doc) => doc.data()['url'] as String)
          .toList();
      notifyListeners();
    }, onError: (error) => debugPrint('Error fetching promos: $error'));

    firestore
        .collection('recordings')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _recordings = snapshot.docs
              .map((doc) => RecordingModel.fromFirestore(doc))
              .toList();
          notifyListeners();
        }, onError: (error) => debugPrint('Error fetching recordings: $error'));

    firestore
        .collection('studypacks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _studyPacks = snapshot.docs
              .map((doc) => StudyPackModel.fromFirestore(doc))
              .toList();
          notifyListeners();
        }, onError: (error) => debugPrint('Error fetching studypacks: $error'));

    firestore
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          _announcements = snapshot.docs
              .map((doc) => AnnouncementModel.fromFirestore(doc))
              .toList();
          notifyListeners();
        }, onError: (error) => debugPrint('Error fetching announcements: $error'));
  }

  // Fetch current user's purchased courses
  Future<void> fetchMyCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _myCourses = [];
      notifyListeners();
      return;
    }

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .where('status', isEqualTo: 'purchased')
          .get();

      final purchasedIds = snapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toSet();

      _myCourses = _courses.where((c) => purchasedIds.contains(c.id)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching my courses: $e');
    }
  }

  // Admin: Add new course
  Future<void> addCourse(CourseModel course) async {
    try {
      await firestore.collection('courses').add(course.toFirestore());
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding course: $e');
      rethrow;
    }
  }

  // Admin: Delete course
  Future<void> deleteCourse(String courseId) async {
    try {
      await firestore.collection('courses').doc(courseId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting course: $e');
      rethrow;
    }
  }

  // Admin: Add Promo Banner URL
  Future<void> addPromoUrl(String url) async {
    try {
      await firestore.collection('promos').add({
        'url': url,
        'createdAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding promo: $e');
      rethrow;
    }
  }

  // Admin: Upload and Add Promo Image
  Future<void> uploadPromoImage(Uint8List imageBytes) async {
    try {
      _isLoading = true;
      notifyListeners();

      final storageRef = FirebaseStorage.instance.ref();
      final fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.png';
      final promoRef = storageRef.child('promos/$fileName');

      // Use SettableMetadata to specify the content type, which helps with 
      // some delivery issues and browser/app caching.
      final metadata = SettableMetadata(contentType: 'image/png');
      
      final uploadTask = await promoRef.putData(imageBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await addPromoUrl(downloadUrl);
    } catch (e) {
      debugPrint('Error uploading promo image: $e');
      // Rethrow with more context if it's a StorageException
      if (e is FirebaseException) {
        throw 'Firebase Error (${e.code}): ${e.message}';
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Delete Promo Banner URL
  Future<void> deletePromoUrl(String docId) async {
    try {
      await firestore.collection('promos').doc(docId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting promo: $e');
      rethrow;
    }
  }

  Future<String> getEnrollmentStatusForCourse(String courseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'available';

    try {
      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(courseId)
          .get();

      if (doc.exists) {
        return doc.data()?['status'] ?? 'pending';
      }
      return 'available';
    } catch (e) {
      debugPrint('Error getting enrollment status: $e');
      return 'available';
    }
  }

  // Send request for course
  Future<void> requestCourseEnrollment({
    required String courseId,
    required String courseTitle,
    required String studentName,
    required String studentEmail,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(courseId)
          .set({
            'courseId': courseId,
            'courseTitle': courseTitle,
            'studentName': studentName,
            'studentEmail': studentEmail,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
          });
      notifyListeners();
    } catch (e) {
      debugPrint('Error requesting course: $e');
      rethrow;
    }
  }

  // Directly enroll user after successful Stripe payment
  Future<void> enrollUserImmediately({
    required String courseId,
    required String courseTitle,
    required String studentName,
    required String studentEmail,
    required String paymentIntentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(courseId)
          .set({
            'courseId': courseId,
            'courseTitle': courseTitle,
            'studentName': studentName,
            'studentEmail': studentEmail,
            'status': 'purchased',
            'purchasedAt': FieldValue.serverTimestamp(),
            'paymentIntentId': paymentIntentId,
            'paymentMethod': 'stripe',
          });
      // Refresh the user's courses list
      await fetchMyCourses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error enrolling user immediately: $e');
      rethrow;
    }
  }

  // Admin: Add Study Pack
  Future<void> addStudyPack(StudyPackModel studyPack) async {
    try {
      await firestore.collection('studypacks').add(studyPack.toFirestore());
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding study pack: $e');
      rethrow;
    }
  }

  // Admin: Delete Study Pack
  Future<void> deleteStudyPack(String packId) async {
    try {
      await firestore.collection('studypacks').doc(packId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting study pack: $e');
      rethrow;
    }
  }

  // Admin: Add Recording
  Future<void> addRecording(RecordingModel recording) async {
    try {
      await firestore.collection('recordings').add(recording.toFirestore());
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding recording: $e');
      rethrow;
    }
  }

  // Admin: Delete Recording
  Future<void> deleteRecording(String recordingId) async {
    try {
      await firestore.collection('recordings').doc(recordingId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      rethrow;
    }
  }

  // Admin: Add Announcement / In-App Message
  Future<void> addAnnouncement(AnnouncementModel announcement) async {
    try {
      await firestore.collection('announcements').add(announcement.toFirestore());
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding announcement: $e');
      rethrow;
    }
  }

  // Admin: Delete Announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await firestore.collection('announcements').doc(announcementId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      rethrow;
    }
  }

  // Check if user has any approved enrollment
  Future<bool> hasApprovedEnrollment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if user is admin
    if (user.email?.toLowerCase() == 'admin@eximgraphics.com') return true;

    try {
      final snapshot = await firestore
          .collectionGroup('enrollments')
          .where('studentEmail', isEqualTo: user.email)
          .where('status', isEqualTo: 'purchased')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking approved enrollment: $e');
      return false;
    }
  }
}
