// Dosya: lib/views/profile_view/notifications_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/services/social_service.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/app/router.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'İletişim Merkezi',
          style: TextStyle(color: AppTheme.primaryBlue),
        ),
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Bildirimler"),
            Tab(text: "Hareket Dökümü"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: "Bildirimleri Temizle",
            onPressed: () {
              SocialService.instance.clearAllNotifications();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Sayfaları ayrı widgetlara böldük ve KeepAlive ekledik
          NotificationListTab(),
          ActivityLogTab(),
        ],
      ),
    );
  }
}

// --- 1. BİLDİRİMLER SEKMESİ (KeepAlive Ekli) ---
class NotificationListTab extends StatefulWidget {
  const NotificationListTab({super.key});

  @override
  State<NotificationListTab> createState() => _NotificationListTabState();
}

class _NotificationListTabState extends State<NotificationListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Sayfayı canlı tut

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Giriş yapın."));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('recipient_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Henüz bir bildirim yok.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        docs.sort((a, b) {
          Timestamp? t1 = a['timestamp'];
          Timestamp? t2 = b['timestamp'];
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            bool isRead = data['is_read'] ?? false;

            return Container(
              color: isRead
                  ? Colors.transparent
                  : AppTheme.primaryBlue.withOpacity(0.05),
              child: ListTile(
                leading: _buildIcon(data['type']),
                title: Text(
                  data['message'] ?? '',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _formatDate(data['timestamp']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () async {
                  await SocialService.instance.markNotificationAsRead(doc.id);
                  _navigateBasedOnType(context, data);
                },
              ),
            );
          },
        );
      },
    );
  }
}

// --- 2. HAREKET DÖKÜMÜ SEKMESİ (KeepAlive Ekli) ---
class ActivityLogTab extends StatefulWidget {
  const ActivityLogTab({super.key});

  @override
  State<ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<ActivityLogTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Sayfayı canlı tut (Yanıp sönmeyi engeller)

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_activities')
          .where('user_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Henüz bir hareketiniz yok.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        docs.sort((a, b) {
          Timestamp? t1 = a['timestamp'];
          Timestamp? t2 = b['timestamp'];
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(
                data['text'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                _formatDate(data['timestamp']),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
              onTap: () {
                if (data['movie_id'] != null && data['movie_id'] != 0) {
                  _goToMovie(context, data['movie_id']);
                }
              },
            );
          },
        );
      },
    );
  }
}

// --- YARDIMCI FONKSİYONLAR ---

Widget _buildIcon(String? type) {
  IconData icon = Icons.notifications;
  Color color = AppTheme.primaryBlue;

  if (type == 'message') {
    icon = Icons.mail;
    color = Colors.orange;
  } else if (type == 'friend_request') {
    icon = Icons.person_add;
    color = Colors.green;
  } else if (type == 'like') {
    icon = Icons.favorite;
    color = Colors.redAccent;
  } else if (type == 'comment') {
    icon = Icons.comment;
    color = Colors.purpleAccent;
  }

  return CircleAvatar(
    backgroundColor: AppTheme.surfaceDark,
    child: Icon(icon, color: color, size: 20),
  );
}

String _formatDate(dynamic timestamp) {
  if (timestamp == null) return '';
  if (timestamp is Timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
  return '';
}

void _navigateBasedOnType(BuildContext context, Map<String, dynamic> data) {
  String type = data['type'] ?? '';

  if (type == 'message' || type == 'friend_request') {
    context.push(AppRouters.friends);
  } else if (data['movie_id'] != null && data['movie_id'] != 0) {
    _goToMovie(context, data['movie_id']);
  }
}

void _goToMovie(BuildContext context, int movieId) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Film açılıyor..."),
      duration: Duration(seconds: 1),
    ),
  );
  try {
    final movie = await MovieManager.instance.getMovieById(movieId);
    if (movie != null && context.mounted) {
      context.push('/movie-detail', extra: movie);
    }
  } catch (e) {
    // Hata yok say
  }
}
