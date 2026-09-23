import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

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
                'Refund Policy',
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
                'Thank you for shopping at Shilpa Sena LMS. We value your satisfaction and strive to provide you with the best online shopping and learning experience possible. If, for any reason, you are not completely satisfied with your purchase, we are here to help.',
              ),
              _buildSectionTitle('Returns'),
              _buildSectionText(
                'We accept returns within 30 days from the date of purchase. To be eligible for a return, your item must be unused and in the same condition that you received it. It must also be in the original packaging.',
              ),
              _buildSectionTitle('Refunds'),
              _buildSectionText(
                'Once we receive your return and inspect the item, we will notify you of the status of your refund. If your return is approved, we will initiate a refund to your original method of payment excluding initial shipping charges.',
              ),
              _buildSectionTitle('Exchanges'),
              _buildSectionText(
                'If you would like to exchange your item for a different size, color, or style, please contact our customer support team within 30 days of receiving your order.',
              ),
              _buildSectionTitle('Non-Returnable Items'),
              _buildSectionText(
                'Certain items are non-returnable and non-refundable:\n'
                '• Gift cards\n'
                '• Downloadable software products\n'
                '• Personalized or custom-made items\n'
                '• Perishable goods',
              ),
              _buildSectionTitle('Damaged or Defective Items'),
              _buildSectionText(
                'In the unfortunate event that your item arrives damaged or defective, please contact us immediately. We will arrange a replacement or issue a refund based on product availability.',
              ),
              _buildSectionTitle('Return Shipping'),
              _buildSectionText(
                'You will be responsible for return shipping costs unless the return is due to our error (e.g. wrong item shipped, defective product), in which case a prepaid shipping label will be provided.',
              ),
              _buildSectionTitle('Processing Time'),
              _buildSectionText(
                'Refunds and exchanges will be processed within 5 business days after receiving your returned item.',
              ),
              _buildSectionTitle('Contact Us'),
              _buildSectionText(
                'If you have any questions or concerns regarding our refund policy, please contact our customer support team.',
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
