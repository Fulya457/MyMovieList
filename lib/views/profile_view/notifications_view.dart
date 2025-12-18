import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/services/social_service.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // --- SİLME BUTONU ---
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text(
                    "Tümünü Sil?",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    "Bütün bildirim geçmişin silinecek.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await SocialService.instance.clearAllNotifications();
                        if (context.mounted) Navigator.pop(ctx);
                      },
                      child: const Text(
                        "Sil",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipient_id', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty)
            return const Center(
              child: Text(
                "Bildirim yok.",
                style: TextStyle(color: Colors.grey),
              ),
            );

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              IconData icon = Icons.notifications;
              if (data['type'] == 'like') icon = Icons.favorite;
              if (data['type'] == 'comment') icon = Icons.comment;
              if (data['type'] == 'reply') icon = Icons.reply;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.surfaceDark,
                  child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
                ),
                title: Text(
                  data['message'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp)
                            .toDate()
                            .toString()
                            .substring(0, 16)
                      : '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
