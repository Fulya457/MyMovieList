import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Giriş yapmalısınız.")));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text("Bildirimler", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipient_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. YÜKLENİYOR DURUMU
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          // 2. HATA DURUMU
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Bir hata oluştu.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // 3. BOŞ LİSTE DURUMU
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    "Henüz bir bildiriminiz yok.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 4. LİSTELEME
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String type = data['type'] ?? 'info';
              final String message = data['message'] ?? '';
              final int movieId = data['movie_id'] ?? 0;
              final Timestamp? ts = data['timestamp'];
              final timeStr = ts != null
                  ? DateFormat('dd MMM HH:mm').format(ts.toDate())
                  : '';

              IconData icon;
              Color iconColor;

              switch (type) {
                case 'like':
                  icon = Icons.favorite;
                  iconColor = Colors.red;
                  break;
                case 'reply':
                  icon = Icons.reply;
                  iconColor = Colors.blue;
                  break;
                case 'comment':
                  icon = Icons.edit_note;
                  iconColor = Colors.green;
                  break;
                default:
                  icon = Icons.info;
                  iconColor = Colors.grey;
              }

              return ListTile(
                tileColor: AppTheme.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.2),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                title: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  timeStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () async {
                  if (movieId != 0) {
                    // Loading göster
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    final movie = await MovieManager.instance.getMovieById(
                      movieId,
                    );

                    if (context.mounted) Navigator.pop(context); // Loading kapa

                    if (movie != null && context.mounted) {
                      context.push('/movie-detail', extra: movie);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Film bulunamadı.")),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
