import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "Yeni Grup Kur",
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                hintText: "Grup Adı",
                hintStyle: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.black12,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                hintText: "Açıklama (Örn: Korku filmi severler)",
                hintStyle: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.black12,
              ),
            ),
          ],
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
              if (nameController.text.trim().isNotEmpty) {
                await MovieManager.instance.createGroup(
                  nameController.text.trim(),
                  descController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Grup oluşturuldu!")),
                  );
                }
              }
            },
            child: const Text("Oluştur", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        title: const Text("Film Toplulukları"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Grup Kur", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppTheme.textColor),
              onChanged: (val) =>
                  setState(() => _searchText = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Grup ara...",
                hintStyle: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: MovieManager.instance.getGroupsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchText);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final members = List<String>.from(data['members'] ?? []);
                    final pending = List<String>.from(
                      data['pending_requests'] ?? [],
                    );
                    final isMember = members.contains(myUid);
                    final isPending = pending.contains(myUid);
                    final isCreator = data['creator_id'] == myUid;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: AppTheme.surfaceDark,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withValues(
                            alpha: 0.2,
                          ),
                          child: Icon(Icons.group, color: AppTheme.primaryBlue),
                        ),
                        title: Text(
                          data['name'],
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${data['description']}\n${members.length} Üye",
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: isMember
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.withValues(
                                    alpha: 0.2,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  context.push(
                                    AppRouters.groupChat,
                                    extra: {
                                      'groupId': doc.id,
                                      'groupName': data['name'],
                                      'isCreator': isCreator,
                                    },
                                  );
                                },
                                child: const Text(
                                  "Sohbet",
                                  style: TextStyle(color: Colors.green),
                                ),
                              )
                            : (isPending
                                  ? const Text(
                                      "İstek Gönderildi",
                                      style: TextStyle(color: Colors.orange),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                      ),
                                      onPressed: () async {
                                        await MovieManager.instance
                                            .requestJoinGroup(doc.id);
                                        if (mounted)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Katılma isteği gönderildi.",
                                              ),
                                            ),
                                          );
                                      },
                                      child: const Text(
                                        "Katıl",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
