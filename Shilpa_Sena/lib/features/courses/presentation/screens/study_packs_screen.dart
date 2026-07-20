import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/database_provider.dart';
import 'package:exim_graphics_lms/models/recording_model.dart'; // Reuse Recording model for simplicity if same structure
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import '../../../home/presentation/widgets/section_carousel.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class StudyPacksScreen extends StatefulWidget {
  const StudyPacksScreen({super.key});

  @override
  State<StudyPacksScreen> createState() => _StudyPacksScreenState();
}

class _StudyPacksScreenState extends State<StudyPacksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Study Materials',
        showDrawerButton: true,
      ),
      drawer: const AppDrawer(),
      body: CustomBackground(
        child: FutureBuilder<bool>(
          future: context.read<DatabaseProvider>().hasApprovedEnrollment(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: DesignConstants.primaryCyan));
            }
            
            final isEnrolled = snapshot.data ?? false;
            
            if (!isEnrolled) {
              return _buildLockedState();
            }

            return Consumer<DatabaseProvider>(
              builder: (context, dbProvider, _) {
                final packs = dbProvider.recordings; // Assuming study packs are in same list or similar
                
                if (packs.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      SectionCarousel<RecordingModel>(
                        title: 'Learning Resources',
                        items: packs,
                        itemBuilder: (context, pack) => _buildPackCard(context, pack),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackCard(BuildContext context, RecordingModel pack) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: DesignConstants.cardGradient,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchURL(context, pack.videoUrl),
          borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: DesignConstants.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: DesignConstants.primaryCyan, size: 30),
                ),
                const Spacer(),
                Text(
                  pack.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PDF Document',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_outlined, color: DesignConstants.notificationRed, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Enrollment Required',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Comprehensive study packs and materials are available exclusively for enrolled students.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/courses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignConstants.primaryCyan,
                foregroundColor: DesignConstants.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Enroll Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, color: Colors.white10, size: 80),
          SizedBox(height: 16),
          Text(
            'No study materials currently uploaded',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch document link')),
        );
      }
    }
  }
}
