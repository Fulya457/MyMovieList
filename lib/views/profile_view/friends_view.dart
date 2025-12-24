// Dosya: lib/views/profile_view/friends_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Helper Methods (Search, Format Name etc.)
  String _formatName(String email) {
    if (email.contains('@')) return email.split('@')[0].toUpperCase();
    return email.toUpperCase();
  }

  void _showSearchUserDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String searchEmail = "";
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text(
            "Arkadaş Ekle",
            style: TextStyle(color: AppTheme.textColor),
          ),
          content: TextField(
            style: TextStyle(color: AppTheme.textColor),
            decoration: InputDecoration(
              hintText: "E-posta adresi girin...",
              hintStyle: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
              filled: true,
              fillColor: Colors.black12,
            ),
            onChanged: (val) => searchEmail = val.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              onPressed: () async {
                if (searchEmail.isNotEmpty) {
                  Navigator.pop(ctx);
                  final users = await MovieManager.instance.searchUsersByEmail(
                    searchEmail,
                  );
                  if (users.isNotEmpty && mounted) {
                    await MovieManager.instance.sendFriendRequest(
                      users.first['uid'],
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${users.first['email']} kullanıcısına istek gönderildi!",
                        ),
                      ),
                    );
                  } else {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Kullanıcı bulunamadı.")),
                      );
                  }
                }
              },
              child: const Text("Ekle", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Sosyal Çevre',
          style: TextStyle(color: AppTheme.textColor),
        ),
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: IconThemeData(color: AppTheme.iconColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Arkadaşlarım"),
            Tab(text: "İstekler"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1, color: AppTheme.primaryBlue),
            onPressed: _showSearchUserDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFriendsList(), _buildRequestsList()],
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: MovieManager.instance.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return Center(
            child: Text(
              "Henüz arkadaşın yok.",
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.5),
              ),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            final email = data['email'] ?? 'Unknown';
            final name = _formatName(email);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _UserAvatar(uid: uid, radius: 24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.primaryBlue,
                    ),
                    onPressed: () => context.push(
                      AppRouters.chat,
                      extra: {'targetUid': uid, 'targetEmail': email},
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.person_remove_outlined,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => MovieManager.instance.removeFriend(uid),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: MovieManager.instance.getFriendRequestsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return Center(
            child: Text(
              "Gelen istek yok.",
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.5),
              ),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            final email = data['email'] ?? 'Unknown';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _UserAvatar(uid: uid, radius: 20),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () =>
                        MovieManager.instance.acceptFriendRequest(uid, email),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => MovieManager.instance.removeFriend(uid),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String uid;
  final double radius;
  const _UserAvatar({required this.uid, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? iconUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final iconIndex = data['profile_icon_id'] ?? 0;
          if (iconIndex >= 0 &&
              iconIndex < MovieManager.instance.profileIcons.length) {
            iconUrl = MovieManager.instance.profileIcons[iconIndex];
          }
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          backgroundImage: iconUrl != null ? NetworkImage(iconUrl) : null,
          child: iconUrl == null
              ? Icon(Icons.person, size: radius, color: Colors.grey)
              : null,
        );
      },
    );
  }
}
