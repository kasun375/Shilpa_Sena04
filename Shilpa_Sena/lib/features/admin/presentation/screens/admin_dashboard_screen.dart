import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:exim_graphics_lms/core/presentation/widgets/custom_background.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Admin Control Center',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: CustomBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  color: DesignConstants.primaryCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    context,
                    title: 'Manage Courses',
                    subtitle: 'Add or Edit Courses',
                    icon: Icons.library_books_outlined,
                    color: DesignConstants.primaryCyan,
                    onTap: () => context.push('/admin/manage-courses'),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Student Directory',
                    subtitle: 'View All Users',
                    icon: Icons.group_outlined,
                    color: Colors.purpleAccent,
                    onTap: () => context.push('/admin/manage-users'),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Enrollment Requests',
                    subtitle: 'Approve Access',
                    icon: Icons.how_to_reg_outlined,
                    color: Colors.greenAccent,
                    onTap: () => context.push('/admin/manage-students'),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Promos & Banners',
                    subtitle: 'Update App Carousel',
                    icon: Icons.image_outlined,
                    color: DesignConstants.accentYellow,
                    onTap: () => context.push('/admin/manage-promos'),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Manage Recordings',
                    subtitle: 'Add Class Videos',
                    icon: Icons.video_collection_outlined,
                    color: DesignConstants.notificationRed,
                    onTap: () => context.push('/admin/manage-recordings'),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Manage Study Packs',
                    subtitle: 'Drive Link Resources',
                    icon: Icons.folder_copy_outlined,
                    color: Colors.amber,
                    onTap: () => context.push('/admin/manage-study-packs'),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'In-App Messages',
                    subtitle: 'Broadcast Alerts',
                    icon: Icons.notifications_active_outlined,
                    color: Colors.tealAccent,
                    onTap: () => context.push('/admin/manage-announcements'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            DesignConstants.primaryBlue,
            DesignConstants.primaryCyan,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: DesignConstants.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back, Admin!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your LMS platform efficiently.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: DesignConstants.cardGradient,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadius),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
