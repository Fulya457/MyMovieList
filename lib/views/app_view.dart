// Dosya: lib/views/app_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/app/router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymovielist/services/social_service.dart';
import 'dart:async';

class AppView extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppView({super.key, required this.navigationShell});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  StreamSubscription? _notificationSubscription;
  // İlk açılışta eski bildirimleri basmasın diye zaman damgası tutuyoruz
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Widget çizildikten hemen sonra dinlemeyi başlat
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
    if (user == null) {
      print("DEBUG: Kullanıcı oturum açmamış, bildirim dinlenemiyor.");
      return;
    }

    print("DEBUG: Bildirim dinleyicisi başlatılıyor... (User: ${user.uid})");

    // SORGUSU: Sadece bana gelenler
    // Hata riskini azaltmak için orderBy kaldırdık, Dart tarafında süzeriz.
    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipient_id', isEqualTo: user.uid)
        .snapshots();

    _notificationSubscription = stream.listen(
      (snapshot) {
        print(
          "DEBUG: Veritabanında hareket algılandı! Doküman sayısı: ${snapshot.docs.length}",
        );

        for (var change in snapshot.docChanges) {
          // Sadece YENİ eklenenleri (Added) yakala
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            final docId = change.doc.id;

            // Kontrol 1: Okunmuş mu?
            bool isRead = data['is_read'] ?? false;
            if (isRead) continue;

            // Kontrol 2: Bu bildirim uygulama açıldıktan SONRA mı geldi?
            // (Eski bildirimlerin hepsini birden ekrana basmamak için)

            print("DEBUG: Yeni bildirim gösteriliyor: ${data['message']}");
            _showInAppNotification(context, data, docId);
          }
        }
      },
      onError: (error) {
        print("KIRMIZI ALARM (HATA): Bildirim Stream Hatası: $error");
        // Eğer bu hatayı görürsen Firebase Konsol'da indeks oluşturman gerekir.
        // Konsoldaki linke tıklaman yeterli olur.
      },
    );
  }

  void _showInAppNotification(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    // Mesaj içeriği ve ikonu belirle
    String message = data['message'] ?? 'Yeni bildirim';
    String type = data['type'] ?? 'general';

    IconData icon = Icons.notifications;
    Color iconColor = AppTheme.primaryBlue;

    if (type == 'message') {
      icon = Icons.mail;
      iconColor = Colors.orange;
    } else if (type == 'friend_request') {
      icon = Icons.person_add;
      iconColor = Colors.green;
    } else if (type == 'like') {
      icon = Icons.favorite;
      iconColor = Colors.redAccent;
    } else if (type == 'comment') {
      icon = Icons.comment;
      iconColor = Colors.purpleAccent;
    }

    // SnackBar Göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating, // Havada duran stil
        margin: const EdgeInsets.all(16), // Kenar boşlukları
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5), // Ekranda kalma süresi
        content: Row(
          children: [
            // İkon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Yazı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Yeni Bildirim",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'GİT',
          textColor: AppTheme.primaryBlue,
          onPressed: () {
            // 1. Bildirimi okundu yap (Database)
            SocialService.instance.markNotificationAsRead(docId);

            // 2. SnackBar'ı hemen kapat
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            // 3. İlgili sayfaya yönlendir
            _handleNavigation(type);
          },
        ),
      ),
    );
  }

  void _handleNavigation(String type) {
    if (type == 'friend_request' || type == 'message') {
      // Mesaj veya Arkadaşlık isteğiyse -> Arkadaşlar/Chat sayfasına
      context.push(AppRouters.friends);
    } else {
      // Beğeni, Yorum vb. ise -> Bildirim merkezine
      context.push(AppRouters.notifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.backgroundBlack,
        indicatorColor: AppTheme.primaryBlue.withOpacity(0.2),
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: widget.navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.recommend), label: 'For You'),
        ],
      ),
    );
  }
}
