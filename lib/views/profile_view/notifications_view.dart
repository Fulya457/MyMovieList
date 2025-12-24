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
    // Tema değişince anlık güncellensin diye AnimatedBuilder
    return AnimatedBuilder(
      animation: MovieManager.instance,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack, // Dinamik Arka Plan
          appBar: AppBar(
            title: Text(
              'İletişim Merkezi',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
            backgroundColor: AppTheme.backgroundBlack,
            // İkonlar (Geri tuşu vs.) aydınlık modda görünsün diye:
            iconTheme: IconThemeData(color: AppTheme.textColor),
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
            children: const [NotificationListTab(), ActivityLogTab()],
          ),
        );
      },
    );
  }
}

// --- 1. BİLDİRİMLER SEKMESİ ---
class NotificationListTab extends StatefulWidget {
  const NotificationListTab({super.key});

  @override
  State<NotificationListTab> createState() => _NotificationListTabState();
}

class _NotificationListTabState extends State<NotificationListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Text(
          "Giriş yapın.",
          style: TextStyle(color: AppTheme.textColor),
        ),
      );
    }

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
          return Center(
            child: Text(
              "Henüz bir bildirim yok.",
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        // Tarihe göre sırala
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
                  : AppTheme.primaryBlue.withValues(alpha: 0.05),
              child: ListTile(
                leading: _buildIcon(data['type']),
                title: Text(
                  // Hem 'text' hem 'message' alanını kontrol et
                  data['text'] ?? data['message'] ?? '',
                  style: TextStyle(
                    color: AppTheme.textColor, // MAVİ/KOYU YAZI (Düzeltildi)
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _formatDate(data['timestamp']),
                  style: TextStyle(
                    color: AppTheme.textColor.withValues(
                      alpha: 0.6,
                    ), // Okunaklı Gri/Mavi
                    fontSize: 12,
                  ),
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

// --- 2. HAREKET DÖKÜMÜ SEKMESİ ---
class ActivityLogTab extends StatefulWidget {
  const ActivityLogTab({super.key});

  @override
  State<ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<ActivityLogTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
          return Center(
            child: Text(
              "Henüz bir hareketiniz yok.",
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.5),
              ),
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
              leading: Icon(Icons.history, color: AppTheme.iconColor),
              title: Text(
                data['text'] ?? '',
                style: TextStyle(
                  color: AppTheme.textColor.withValues(
                    alpha: 0.9,
                  ), // MAVİ/KOYU YAZI (Düzeltildi)
                ),
              ),
              subtitle: Text(
                _formatDate(data['timestamp']),
                style: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.6), // Okunaklı
                  fontSize: 11,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.iconColor.withValues(alpha: 0.5),
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
