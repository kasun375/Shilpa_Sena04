import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:exim_graphics_lms/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = firebase_auth.FirebaseAuth.instance;
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfilePicture(File(image.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.5),
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF1E293B),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white24,
                            )
                          : null,
                    ),
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        color: Colors.orangeAccent,
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Anonymous User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Profile Identity',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your profile picture helps instructors and peers recognize you in the LMS community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
