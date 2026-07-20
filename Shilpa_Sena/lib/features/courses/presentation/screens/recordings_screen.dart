import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/database_provider.dart';
import 'package:exim_graphics_lms/models/recording_model.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_app_bar.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';
import '../../../home/presentation/widgets/section_carousel.dart';
import '../../../../core/presentation/widgets/app_drawer.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Course Recordings',
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
                final recordings = dbProvider.recordings;
                
                if (recordings.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      SectionCarousel<RecordingModel>(
                        title: 'Latest Recordings',
                        items: recordings,
                        itemBuilder: (context, recording) => _buildRecordingCard(context, recording),
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

  Widget _buildRecordingCard(BuildContext context, RecordingModel recording) {
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
          onTap: () => _launchURL(context, recording.videoUrl),
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
                  child: const Icon(Icons.play_circle_outline, color: DesignConstants.primaryCyan, size: 30),
                ),
                const Spacer(),
                Text(
                  recording.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      recording.uploadedAt.toString().split(' ')[0],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
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
            const Icon(Icons.lock_outline, color: DesignConstants.notificationRed, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Access Restricted',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please enroll in a course to access our exclusive recordings library.',
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
              child: const Text('Browse Courses', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Icon(Icons.video_library_outlined, color: Colors.white10, size: 80),
          SizedBox(height: 16),
          Text(
            'No recordings available in this section',
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
          const SnackBar(content: Text('Could not launch video link')),
        );
      }
    }
  }
}
