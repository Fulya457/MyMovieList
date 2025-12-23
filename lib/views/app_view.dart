import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/app/router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AppView extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppView({super.key, required this.navigationShell});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningForNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _startListeningForNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Son 10 saniye içindeki bildirimleri dinle (Eski bildirimlerin aniden çıkmasını önlemek için)
    // Ancak Firestore'da timestamp filtresi bazen karmaşık olabilir, basitçe okunmamışlara bakalım.
    // Daha iyi bir yöntem: Dinlemeye başladığımız andan sonrakileri gösterelim.
    // Şimdilik sadece 'is_read: false' olanları dinliyoruz.
    
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipient_id', isEqualTo: user.uid)
        .where('is_read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(1) // Sadece en son gelen bildirimi alalım
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            // Bildirimin yeni olduğunu anlamak için timestamp kontrolü yapılabilir
            // Veya basitçe her değişiklikte göster (bazen aynı bildirim update olursa tekrar çıkabilir, dikkat)
            
            // Veriyi al
            final data = doc.data();
            final message = data['message'] as String? ?? 'Yeni bildirim';
            
            // Eğer bildirim yeni gelmişse göster (Daha önce gösterildiyse tekrar gösterme mantığı eklenebilir)
            // Biz basitçe kullanıcıya gösterip, ardından 'gösterildi' olarak işaretlemiyoruz,
            // kullanıcı tıklayınca veya bildirim sayfasına gidince okunmuş sayılacak.
            // Ama sürekli popup çıkmasın diye local bir state tutabiliriz.
            
            // Pratik Çözüm: Snackbar göster.
            if (mounted) {
              // Mevcut snackbar'ı temizle
              ScaffoldMessenger.of(context).clearSnackBars();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.surfaceDark,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: AppTheme.primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'GÖSTER',
                    textColor: AppTheme.primaryBlue,
                    onPressed: () {
                      // Bildirime tıklandığında Bildirimler sayfasına git
                      context.push(AppRouters.notifications);
                      
                      // Bildirimi okundu olarak işaretle
                      doc.reference.update({'is_read': true});
                    },
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: widget.navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(
            icon: Icon(Icons.recommend),
            label: 'Recommended',
          ),
        ],
      ),
    );
  }
}
