import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/presentation/widgets/custom_background.dart';
import '../../../../core/theme/design_constants.dart';
import '../../../courses/presentation/providers/database_provider.dart';
import '../../../../models/announcement_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().reload();
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Notification Center',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  tooltip: 'Clear Alerts',
                  onPressed: () {
                    // Confirm before clearing system alerts
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: DesignConstants.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        title: const Text(
                          'Clear System Alerts',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to clear all system alerts?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<NotificationProvider>().clearAll();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: DesignConstants.primaryCyan,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_none, size: 20),
                    const SizedBox(width: 8),
                    const Text('System Alerts'),
                    const SizedBox(width: 6),
                    Consumer<NotificationProvider>(
                      builder: (context, provider, _) {
                        final count = provider.unreadCount;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: DesignConstants.notificationRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.campaign_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Announcements'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: CustomBackground(
          child: TabBarView(
            children: [
              _buildSystemAlertsTab(context),
              _buildAnnouncementsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemAlertsTab(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final notifications = provider.notifications;

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white30),
                SizedBox(height: 16),
                Text(
                  'No system alerts yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Card(
              color: DesignConstants.cardBackground,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: notification.isRead 
                      ? Colors.white.withOpacity(0.05) 
                      : DesignConstants.primaryCyan.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  backgroundColor: DesignConstants.primaryCyan.withOpacity(0.1),
                  child: const Icon(Icons.notifications_active, color: DesignConstants.primaryCyan),
                ),
                title: Text(
                  notification.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      notification.body,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.timestamp),
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsTab(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, child) {
        final announcements = dbProvider.announcements;

        if (announcements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.white30),
                SizedBox(height: 16),
                Text(
                  'No announcements broadcasted yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final AnnouncementModel item = announcements[index];
            Color accentColor;
            IconData iconData;

            switch (item.type) {
              case 'alert':
                accentColor = DesignConstants.notificationRed;
                iconData = Icons.warning_amber_rounded;
                break;
              case 'promo':
                accentColor = DesignConstants.accentYellow;
                iconData = Icons.campaign_rounded;
                break;
              default:
                accentColor = DesignConstants.primaryCyan;
                iconData = Icons.info_outline_rounded;
            }

            final hasAction = item.actionUrl != null && item.actionUrl!.isNotEmpty;

            return Card(
              color: DesignConstants.cardBackground,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: accentColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: hasAction ? () => _launchActionUrl(item.actionUrl) : null,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area with Icon, Type and Timestamp
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: accentColor.withOpacity(0.1),
                            child: Icon(iconData, color: accentColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(item.timestamp),
                                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Text Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        item.body,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),

                    // Optional Image Attachment
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 160,
                                color: Colors.white.withOpacity(0.05),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(DesignConstants.primaryCyan),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],

                    // Action Button (Launcher)
                    if (hasAction) ...[
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Learn More',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: accentColor,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchActionUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      if (difference.inMinutes <= 1) return 'Just now';
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
