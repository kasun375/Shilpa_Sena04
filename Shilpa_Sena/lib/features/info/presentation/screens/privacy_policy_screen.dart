import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Your Privacy Matters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Last Updated: March 1, 2026',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'We collect information to provide better services to all our users. The information we collect is used to personalize your learning experience, communicate with you, and process course enrollments. We work hard to protect your data from unauthorized access, alteration, disclosure, or destruction.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 100),
              _buildSocialSupport(),
            ],
          ),
        ),
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
              'https://upload.wikimedia.org/wikipedia/commons/5/51/Facebook_f_logo_%282019%29.svg',
              () => _launchURL('https://www.facebook.com/eximgraphics'),
              color: const Color(0xFF1877F2),
            ),
            const SizedBox(width: 12),
            _buildSocialIcon(
              'https://upload.wikimedia.org/wikipedia/commons/e/e7/Instagram_logo_2016.svg',
              () => _launchURL('https://www.instagram.com/eximgraphics'),
              isGradient: true,
            ),
            const SizedBox(width: 12),
            _buildSocialIcon(
              'https://upload.wikimedia.org/wikipedia/commons/0/09/YouTube_full-color_icon_%282017%29.svg',
              () => _launchURL('https://www.youtube.com/channel/@eximgraphics'),
              color: const Color(0xFFFF0000),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String iconUrl, VoidCallback onTap, {Color? color, bool isGradient = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white, // In the image they look like solid buttons with colored icons or backgrounds
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isGradient 
            ? ShaderMask(
                shaderCallback: (bounds) => const RadialGradient(
                  center: Alignment.bottomLeft,
                  radius: 0.85,
                  colors: [Colors.yellow, Colors.red, Colors.purple],
                ).createShader(bounds),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
              )
            : Icon(
                color == const Color(0xFF1877F2) ? Icons.facebook : Icons.play_circle_filled,
                color: color,
                size: 32,
              ),
        ),
      ),
    );
  }
}
