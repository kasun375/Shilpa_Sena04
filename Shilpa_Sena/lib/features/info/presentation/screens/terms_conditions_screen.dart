import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Last Updated: September 23, 2026',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionText(
                'Welcome to Shilpa Sena LMS. These Terms and Conditions govern your use of our website and application, and the purchase and sale of products from our platform. By accessing and using our platform, you agree to comply with these terms. Please read them carefully before proceeding with any transactions.',
              ),
              _buildSectionTitle('1. Use of the Website'),
              _buildSectionText(
                'a. You must be at least 18 years old to use our website or make purchases.\n'
                'b. You are responsible for maintaining the confidentiality of your account information, including your username and password.\n'
                'c. You agree to provide accurate and current information during the registration and checkout process.\n'
                'd. You may not use our website for any unlawful or unauthorized purposes.',
              ),
              _buildSectionTitle('2. Product Information and Pricing'),
              _buildSectionText(
                'a. We strive to provide accurate product descriptions, images, and pricing information. However, we do not guarantee the accuracy or completeness of such information.\n'
                'b. Prices are subject to change without notice. Any promotions or discounts are valid for a limited time and may be subject to additional terms.',
              ),
              _buildSectionTitle('3. Orders and Payments'),
              _buildSectionText(
                'a. By placing an order, you make an offer to purchase the selected products.\n'
                'b. We reserve the right to refuse or cancel any order for any reason, including product availability or suspected fraud.\n'
                'c. You agree to provide valid payment details and authorize total order charges.\n'
                'd. We use trusted third-party payment processors. Full payment details are not stored on our servers.',
              ),
              _buildSectionTitle('4. Shipping and Delivery'),
              _buildSectionText(
                'a. Reasonable efforts will be made to ensure timely delivery of your orders.\n'
                'b. Delivery dates are estimates and may vary by location and external conditions.',
              ),
              _buildSectionTitle('5. Returns and Refunds'),
              _buildSectionText(
                'Our Returns and Refund Policy governs the process and conditions for returning products and seeking refunds. Please refer to our Refund Policy page for full details.',
              ),
              _buildSectionTitle('6. Intellectual Property'),
              _buildSectionText(
                'a. All content on our platform (text, images, graphics, logos) is protected by intellectual property rights.\n'
                'b. You may not reproduce, distribute, or modify content without prior written consent.',
              ),
              _buildSectionTitle('7. Limitation of Liability'),
              _buildSectionText(
                'In no event shall Shilpa Sena LMS or its affiliates be liable for direct, indirect, incidental, or consequential damages arising out of your use of our platform.',
              ),
              _buildSectionTitle('8. Amendments'),
              _buildSectionText(
                'We reserve the right to modify these Terms and Conditions at any time without prior notice. Please review them periodically.',
              ),
              const SizedBox(height: 40),
              _buildSocialSupport(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00D2FF),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xE6FFFFFF),
        fontSize: 15,
        height: 1.5,
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
        decoration: const BoxDecoration(
          color: Colors.white,
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
