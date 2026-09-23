import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:exim_graphics_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:exim_graphics_lms/core/theme/design_constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: DesignConstants.primaryDark,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: DesignConstants.primaryDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: DesignConstants.primaryBlue,
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? 'Student',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(context, Icons.home, 'Home', () {
                  context.pop();
                  context.go('/home');
                }),
                _buildDrawerItem(context, Icons.school, 'My Courses', () {
                  context.pop();
                  context.push('/my-courses');
                }),
                _buildDrawerItem(context, Icons.book, 'All Courses', () {
                  context.pop();
                  context.push('/courses');
                }),
                _buildDrawerItem(context, Icons.video_library, 'Recordings', () {
                  context.pop();
                  context.push('/recordings');
                }),
                _buildDrawerItem(context, Icons.library_books, 'Study Packs', () {
                  context.pop();
                  context.push('/studypacks');
                }),
                _buildDrawerItem(context, Icons.policy, 'Privacy Policy', () {
                  context.pop();
                  context.push('/privacy-policy');
                }),
                _buildDrawerItem(context, Icons.gavel, 'Terms & Conditions', () {
                  context.pop();
                  context.push('/terms-conditions');
                }),
                _buildDrawerItem(context, Icons.receipt_long, 'Refund Policy', () {
                  context.pop();
                  context.push('/refund-policy');
                }),
                _buildDrawerItem(context, Icons.contact_support, 'Contact Us', () {
                  context.pop();
                  context.push('/contact-us');
                }),
                const Divider(color: Colors.white24),
                
                // Admin Section
                if (authProvider.isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'ADMIN SECTION',
                      style: TextStyle(
                        color: DesignConstants.primaryCyan.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildDrawerItem(context, Icons.dashboard_customize, 'Admin Dashboard', () {
                    context.pop();
                    context.push('/admin');
                  }),
                  const Divider(color: Colors.white24),
                ],

                _buildDrawerItem(context, Icons.logout, 'Logout', () async {
                  await authProvider.signOut();
                  if (context.mounted) context.go('/welcome');
                }, color: Colors.redAccent),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      onTap: onTap,
    );
  }
}
