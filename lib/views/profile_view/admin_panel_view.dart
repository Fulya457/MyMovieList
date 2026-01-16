// lib/views/profile_view/admin_panel_view.dart

import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/services/social_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelView extends StatelessWidget {
  const AdminPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text("MODERATOR PANEL"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.comment), text: "Reviews"),
              Tab(icon: Icon(Icons.group), text: "Groups"),
              Tab(icon: Icon(Icons.people), text: "Users"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AdminReviewsTab(), _AdminGroupsTab(), _AdminUsersTab()],
        ),
      ),
    );
  }
}

// --- Yorum Yönetimi Sekmesi ---
class _AdminReviewsTab extends StatelessWidget {
  const _AdminReviewsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: SocialService.instance.getAllReviewsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              color: AppTheme.surfaceDark,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(
                  "${data['user_name']} - ${data['movie_title']}",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(data['comment'] ?? ""),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _confirmDelete(context, docs[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Review?"),
        content: const Text(
          "As a moderator, you are removing this content permanently.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await SocialService.instance.deleteReview(reviewId);
              Navigator.pop(ctx);
            },
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }
}

// --- Grup Yönetimi Sekmesi ---
class _AdminGroupsTab extends StatelessWidget {
  const _AdminGroupsTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: SocialService.instance.getAllGroupsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.group, color: Colors.blue),
              title: Text(
                data['name'],
                style: TextStyle(color: AppTheme.textColor),
              ),
              subtitle: Text("${(data['members'] as List).length} Members"),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () =>
                    SocialService.instance.adminDeleteGroup(doc.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// --- Kullanıcı Listesi Sekmesi ---
// admin_panel_view.dart içindeki kullanıcılar sekmesi

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: SocialService.instance.getAllUsersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final bool isBlocked = data['is_blocked'] ?? false;
            final String email = data['email'] ?? "No Email";
            final String role = data['role'] ?? "user";

            return Card(
              color: AppTheme.surfaceDark,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBlocked
                      ? Colors.red
                      : AppTheme.primaryBlue,
                  child: Icon(
                    isBlocked ? Icons.block : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(email, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  "Rol: $role",
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: role == "admin"
                    ? const Icon(
                        Icons.verified_user,
                        color: Colors.amber,
                      ) // Admin kendini bloklayamaz
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBlocked
                              ? Colors.green
                              : Colors.red,
                        ),
                        onPressed: () => SocialService.instance
                            .adminToggleBlock(users[index].id, !isBlocked),
                        child: Text(isBlocked ? "ENGELİ KALDIR" : "BLOKLA"),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
