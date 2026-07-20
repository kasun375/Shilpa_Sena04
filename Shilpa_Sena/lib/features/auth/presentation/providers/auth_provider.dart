import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:exim_graphics_lms/core/services/notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String _role = 'student'; // Default role
  StreamSubscription<String>? _tokenRefreshSubscription;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin {
    if (_user?.email?.toLowerCase() == 'admin@eximgraphics.com') return true;
    return _role == 'admin';
  }

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserRole(user.uid);
        await _updateFcmToken(user.uid);

        // Listen for token refreshes while the user is logged in
        _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = NotificationService.onTokenRefresh.listen((
          token,
        ) {
          _saveTokenToFirestore(user.uid, token);
        });
      } else {
        _role = 'student';
        _tokenRefreshSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _role = doc.data()?['role'] ?? 'student';
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
    }
  }

  Future<void> _updateFcmToken(String uid) async {
    try {
      String? token = await NotificationService.getToken();
      if (token != null) {
        await _saveTokenToFirestore(uid, token);
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmail(
    String name,
    String email,
    String password, {
    File? profilePicture,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String? photoUrl;
      if (profilePicture != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('${credential.user!.uid}.jpg');
        await ref.putFile(profilePicture);
        photoUrl = await ref.getDownloadURL();
      }

      if (photoUrl != null) {
        await credential.user?.updatePhotoURL(photoUrl);
      }
      await credential.user?.updateDisplayName(name);

      final userRole = email.toLowerCase() == 'admin@eximgraphics.com'
          ? 'admin'
          : 'student';

      // Create user document in Firestore with role
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': userRole,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _role = userRole;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Reverting to .instance as it seems to be what this project's configuration requires
      // although it's non-standard for the public package.
      try {
        await GoogleSignIn.instance.initialize();
      } catch (_) {}

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email ?? '',
          'role': 'student',
          'photoUrl': userCredential.user!.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _fetchUserRole(userCredential.user!.uid);

      _user = userCredential.user;
      notifyListeners();
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  Future<void> updateProfilePicture(File image) async {
    if (_user == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${_user!.uid}.jpg');

      await ref.putFile(image);
      final photoUrl = await ref.getDownloadURL();

      await _user!.updatePhotoURL(photoUrl);
      await _firestore.collection('users').doc(_user!.uid).update({
        'photoUrl': photoUrl,
      });

      // Refresh the user object to reflect changes
      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  static String mapAuthException(dynamic e) {
    if (e is! FirebaseAuthException) return e.toString();

    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }
}
