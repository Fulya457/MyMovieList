// Dosya: lib/views/app_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/app/router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymovielist/services/social_service.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'dart:async';

class AppView extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppView({super.key, required this.navigationShell});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  StreamSubscription? _notificationSubscription;
  late DateTime _appOpenTime;

  @override
  void initState() {
    super.initState();
    _appOpenTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningForNotifications();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _startListeningForNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipient_id', isEqualTo: user.uid)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              final docId = change.doc.id;

              Timestamp? ts = data['timestamp'];
              if (ts == null) continue;

              DateTime msgTime = ts.toDate();
              if (msgTime.isAfter(_appOpenTime)) {
                final text =
                    data['text'] ?? data['message'] ?? 'New Notification';
                final type = data['type'] ?? 'general';

                final manager = MovieManager.instance;

                if (!manager.areNotificationsEnabled) return;

                if (type == 'message') {
                  final senderId = data['sender_id'];
                  if (senderId != null &&
                      senderId == manager.currentChatPartnerId) {
                    SocialService.instance.markNotificationAsRead(docId);
                    return;
                  }
                }

                if (mounted) {
                  _showInAppNotification(text, type, docId);
                }
              }
            }
          }
        });
  }

  void _showInAppNotification(String text, String type, String docId) {
    final isDark = MovieManager.instance.isDarkMode;
    final Color bgColor = isDark ? const Color(0xFF1E202B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        elevation: 10,
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.5), // DÜZELTME
            width: 1.5,
          ),
        ),
        content: Row(
          children: [
            Icon(_getIconForType(type), color: AppTheme.primaryBlue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'SHOW',
          textColor: AppTheme.primaryBlue,
          onPressed: () {
            SocialService.instance.markNotificationAsRead(docId);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _handleNavigation(type);
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'message':
        return Icons.mail;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  void _handleNavigation(String type) {
    switch (type) {
      case 'friend_request':
        context.push(AppRouters.friends);
        break;
      case 'message':
        context.push(AppRouters.friends);
        break;
      default:
        context.push(AppRouters.notifications);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MovieManager.instance,
      builder: (context, child) {
        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppTheme.backgroundBlack,
            indicatorColor: AppTheme.primaryBlue.withOpacity(0.2), // DÜZELTME
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (index) {
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppTheme.primaryBlue),
                label: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category, color: AppTheme.primaryBlue),
                label: 'Categories',
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite, color: AppTheme.primaryBlue),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: const Icon(Icons.recommend_outlined),
                selectedIcon: Icon(
                  Icons.recommend,
                  color: AppTheme.primaryBlue,
                ),
                label: 'For You',
              ),
            ],
          ),
        );
      },
    );
  }
}
