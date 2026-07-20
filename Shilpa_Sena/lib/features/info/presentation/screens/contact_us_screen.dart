import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import 'package:exim_graphics_lms/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

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
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Shilpa Sena',
        showBackButton: true,
      ),
      drawer: const AppDrawer(),
      body: CustomBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Us',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'How can we help you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Our team is here to support your learning journy.Feel free to reach out to us anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // My Profile Identity (Integrated from previous feature)
              _buildUserProfileSection(),
              
              const SizedBox(height: 60),

              // Contact Details
              _buildContactItem(
                label: 'Phone Number',
                value: '076 089 12 62',
                onTap: () => _launchURL('tel:0760891262'),
              ),
              const SizedBox(height: 25),
              _buildContactItem(
                label: 'Whatsapp',
                value: '076 634 18 72',
                onTap: () => _launchURL('https://wa.me/94766341872'),
              ),
              const SizedBox(height: 25),
              _buildContactItem(
                label: 'Email Us',
                value: 'kasunjayaweera80@gmail.com',
                onTap: () => _sendEmail('kasunjayaweera80@gmail.com'),
              ),
              
              const SizedBox(height: 40),
              _buildSocialSupport(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Text(
                'My Profile Identity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: DesignConstants.primaryCyan, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: DesignConstants.primaryCyan.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user?.photoURL != null
                          ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                          : Container(
                              color: DesignConstants.primaryBlue.withOpacity(0.3),
                              child: const Icon(Icons.person, color: Colors.white, size: 60),
                            ),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: DesignConstants.primaryCyan),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DesignConstants.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'Student',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Your profile picture helps instructors and peers recognize you in the LMS community.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Social Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSocialIcon(
              Icons.facebook,
              () => _launchURL('https://www.facebook.com/eximgraphics'),
              color: const Color(0xFF1877F2),
            ),
            const SizedBox(width: 20),
            _buildSocialIcon(
              Icons.camera_alt,
              () => _launchURL('https://www.instagram.com/eximgraphics'),
              isGradient: true,
            ),
            const SizedBox(width: 20),
            _buildSocialIcon(
              Icons.play_circle_filled,
              () => _launchURL('https://www.youtube.com/channel/@eximgraphics'),
              color: const Color(0xFFFF0000),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap, {Color? color, bool isGradient = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: isGradient 
          ? ShaderMask(
              shaderCallback: (bounds) => const RadialGradient(
                center: Alignment.bottomLeft,
                radius: 0.85,
                colors: [Colors.yellow, Colors.red, Colors.purple],
              ).createShader(bounds),
              child: Icon(icon, color: Colors.white, size: 40),
            )
          : Icon(icon, color: color, size: 40),
      ),
    );
  }
}
