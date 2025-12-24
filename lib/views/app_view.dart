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
  // Sayfa açıldığı anı milisaniye olarak alıyoruz
  int _startTimestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
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

    // Sadece bu oturum açıldıktan sonra gelen bildirimleri dinle
    // 'timestamp' alanı Firestore'da ServerTimestamp olmalı.
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipient_id', isEqualTo: user.uid)
        .snapshots() // Tümünü dinle, client tarafında filtrele (Daha güvenilir anlık bildirim için)
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            // Sadece yeni eklenenler (Added)
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              final docId = change.doc.id;

              // Zaman kontrolü: Bildirim yeni mi?
              // (Eğer timestamp alanı yoksa veya null ise eski kabul et)
              Timestamp? ts = data['timestamp'];
              if (ts != null) {
                int msgTime = ts.millisecondsSinceEpoch;
                // Eğer mesajın zamanı, bu ekranın açılış zamanından büyükse göster
                if (msgTime > _startTimestamp) {
                  final text =
                      data['text'] ?? data['message'] ?? 'New Notification';
                  final type = data['type'] ?? 'general';
                  if (mounted) {
                    _showInAppNotification(text, type, docId);
                  }
                }
              }
            }
          }
        });
  }

  void _showInAppNotification(String text, String type, String docId) {
    // Tema Durumu
    final isDark = MovieManager.instance.isDarkMode;
    // Renkler
    final Color bgColor = isDark ? const Color(0xFF1E202B) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        elevation: 10, // Biraz daha gölge
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.5), // Mavi Çerçeve
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
        duration: const Duration(seconds: 5),
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
    if (type == 'friend_request' || type == 'message') {
      context.push(
        AppRouters.friends,
      ); // Veya Chat'e gitmesi daha mantıklı olabilir
    } else {
      context.push(AppRouters.notifications);
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
            indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
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
