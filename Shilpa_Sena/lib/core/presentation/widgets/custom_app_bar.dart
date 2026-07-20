import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/design_constants.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/notification_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showDrawerButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showDrawerButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => context.pop(),
              )
            else if (showDrawerButton)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                return GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: DesignConstants.notificationRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
