import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom app bar for dashboard screens with avatar, user info,
/// notification badge, and popup menu.
class AppHeaderBar extends StatelessWidget {
  final IconData avatarIcon;
  final String greeting;
  final String userName;
  final int unreadCount;
  final VoidCallback onNotificationTap;
  final List<PopupMenuEntry<String>> menuItems;
  final void Function(String) onMenuSelected;

  const AppHeaderBar({
    super.key,
    required this.avatarIcon,
    required this.greeting,
    required this.userName,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.menuItems,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(avatarIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),

          // Name & greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  userName,
                  style: AppTheme.headingMedium.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
                onPressed: onNotificationTap,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryAmber,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
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

          // Settings menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: onMenuSelected,
            itemBuilder: (_) => menuItems,
          ),
        ],
      ),
    );
  }
}
