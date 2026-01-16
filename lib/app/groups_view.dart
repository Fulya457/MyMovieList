// Dosya: lib/views/home_view/groups_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/services/social_service.dart'; // [EKLENDİ]

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  int _selectedIconIndex = 0; // Grup ikonu seçimi için

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    // Her açılışta ikonu sıfırla
    _selectedIconIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: Text(
              "Create New Group",
              style: TextStyle(color: AppTheme.textColor),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // İkon Seçici Başlık
                    const Text(
                      "Select Group Icon",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 10),

                    // İkon Seçici Liste
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: MovieManager.instance.groupIcons.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedIconIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                _selectedIconIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white10,
                                backgroundImage: NetworkImage(
                                  MovieManager.instance.groupIcons[index],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      style: TextStyle(color: AppTheme.textColor),
                      decoration: InputDecoration(
                        hintText: "Group Name",
                        hintStyle: TextStyle(
                          color: AppTheme.textColor.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Colors.black12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      style: TextStyle(color: AppTheme.textColor),
                      decoration: InputDecoration(
                        hintText: "Description (e.g., Horror movie lovers)",
                        hintStyle: TextStyle(
                          color: AppTheme.textColor.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Colors.black12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
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
                      _selectedIconIndex, // Seçilen ikon
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Group created!")),
                      );
                    }
                  }
                },
                child: const Text(
                  "Oluştur",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
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
        title: Text(
          "Film Societies",
          style: TextStyle(color: AppTheme.textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Create a Group",
          style: TextStyle(color: Colors.white),
        ),
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
                hintText: "Search group...",
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

                    // Grup İkonunu Belirle
                    final iconIdx = data['group_icon_id'] ?? 0;
                    final iconUrl =
                        (iconIdx >= 0 &&
                            iconIdx < MovieManager.instance.groupIcons.length)
                        ? MovieManager.instance.groupIcons[iconIdx]
                        : MovieManager
                              .instance
                              .groupIcons[0]; // Hata olursa ilk ikon

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: AppTheme.surfaceDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(iconUrl),
                        ),
                        title: Text(
                          data['name'],
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            "${data['description']}\n${members.length} Member",
                            style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
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
                                      'groupIconUrl':
                                          iconUrl, // İkonu sohbete taşıyoruz
                                    },
                                  );
                                },
                                child: const Text(
                                  "Chat",
                                  style: TextStyle(color: Colors.green),
                                ),
                              )
                            : (isPending
                                  ? const Text(
                                      "Request Sent",
                                      style: TextStyle(color: Colors.orange),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                      ),
                                      onPressed: () async {
                                        // [GÜNCELLENDİ] Admin Kontrolü
                                        final bool isAdmin = await SocialService
                                            .instance
                                            .isAdmin();

                                        if (isAdmin) {
                                          // ADMİN: Onay beklemeden direkt girer
                                          await SocialService.instance
                                              .adminJoinGroupDirectly(doc.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Joined directly as Moderator!",
                                                ),
                                                backgroundColor: Colors.amber,
                                              ),
                                            );
                                          }
                                        } else {
                                          // NORMAL KULLANICI: Onay bekler
                                          await MovieManager.instance
                                              .requestJoinGroup(doc.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "A request to join has been sent.",
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text(
                                        "Join",
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
