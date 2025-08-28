import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_models.dart';
import 'package:photos/services/feed/feed_data_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/feed/widgets/feed_user_avatar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> _unreadNotifications = [];
  List<NotificationItem> _readNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final notifications = FeedDataService.getMockNotifications();
    setState(() {
      _unreadNotifications = notifications.where((n) => !n.isRead).toList();
      _readNotifications = notifications.where((n) => n.isRead).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    
    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back,
                        color: colorScheme.textBase,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unread section
                    if (_unreadNotifications.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          'Unread',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      ..._unreadNotifications.map((notification) => 
                        _buildNotificationItem(notification, colorScheme),),
                      const SizedBox(height: 24),
                    ],
                    // Read section
                    if (_readNotifications.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          'Read',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      ..._readNotifications.map((notification) => 
                        _buildNotificationItem(notification, colorScheme),),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // User avatar
          FeedUserAvatar(
            avatarUrl: notification.user.avatarUrl,
            name: notification.user.name,
            size: 50,
          ),
          const SizedBox(width: 16),
          // Notification details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.textBase,
                    ),
                    children: [
                      TextSpan(
                        text: notification.user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '  ${notification.action}',
                        style: TextStyle(
                          color: colorScheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Photo thumbnail if available
          if (notification.photo != null) ...[
            const SizedBox(width: 12),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: notification.photo!.url,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}