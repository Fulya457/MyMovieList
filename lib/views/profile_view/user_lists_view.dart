// Dosya: lib/views/profile_view/user_lists_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class UserListsView extends StatefulWidget {
  const UserListsView({super.key});

  @override
  State<UserListsView> createState() => _UserListsViewState();
}

class _UserListsViewState extends State<UserListsView> {
  // Helper: Mevcut tema durumunu al
  bool get isDark => MovieManager.instance.isDarkMode;
  Color get dialogBg => isDark ? AppTheme.surfaceDark : Colors.white;
  Color get dialogText => isDark ? Colors.white : Colors.black;
  Color get hintColor => isDark ? Colors.grey : Colors.black54;
  Color get inputFill => isDark ? Colors.black26 : Colors.grey.shade200;

  // --- YENİ LİSTE OLUŞTURMA ---
  void _showCreateListDialog() {
    final nameController = TextEditingController();
    String selectedType = 'movies';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              title: Text(
                "Create New List",
                style: TextStyle(color: dialogText),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: dialogText),
                    decoration: InputDecoration(
                      hintText: "List name...",
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: dialogBg,
                    style: TextStyle(color: dialogText),
                    decoration: InputDecoration(
                      labelText: "List Type",
                      labelStyle: TextStyle(color: AppTheme.primaryBlue),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'movies',
                        child: Text(
                          "Movie List",
                          style: TextStyle(color: dialogText),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'actor',
                        child: Text(
                          "Actor List",
                          style: TextStyle(color: dialogText),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedType = value!),
                  ),
                ],
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
                      await MovieManager.instance.createCustomList(
                        nameController.text.trim(),
                        selectedType,
                      );
                      if (mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    "Create",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- İSİM DEĞİŞTİRME ---
  void _showRenameDialog(String listId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Rename the list", style: TextStyle(color: dialogText)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: dialogText),
          decoration: InputDecoration(
            hintText: "New name..",
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
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
              if (controller.text.trim().isNotEmpty) {
                await MovieManager.instance.renameCustomList(
                  listId,
                  controller.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- PAYLAŞMA ---
  void _showShareSheet(Map<String, dynamic> listData, String listId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.backgroundBlack : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Share List",
                style: TextStyle(
                  color: dialogText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getFriendsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "You have no friends.",
                          style: TextStyle(color: hintColor),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark
                                ? AppTheme.surfaceDark
                                : Colors.grey.shade200,
                            child: Text(
                              (data['email'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          title: Text(
                            data['email'] ?? '',
                            style: TextStyle(color: dialogText),
                          ),
                          trailing: Icon(
                            Icons.send,
                            color: AppTheme.primaryBlue,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            final items = listData['items'] as List? ?? [];
                            final sharedData = {
                              'id': listId,
                              'name': listData['name'],
                              'count': items.length,
                              'type': listData['type'] ?? 'movies',
                              'items': items,
                            };
                            context.push(
                              AppRouters.chat,
                              extra: {
                                'targetUid': data['uid'],
                                'targetEmail': data['email'],
                                'sharedList': sharedData,
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SİLME ---
  void _confirmDelete(String listId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Delete List?", style: TextStyle(color: dialogText)),
        content: Text(
          "This action is irreversible.",
          style: TextStyle(color: hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await MovieManager.instance.deleteCustomList(listId);
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("List deleted.")));
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [ÖNEMLİ] Temayı dinamik dinlemek için AnimatedBuilder
    return AnimatedBuilder(
      animation: MovieManager.instance,
      builder: (context, child) {
        // Dinamik Renkler
        final bool isDark = MovieManager.instance.isDarkMode;
        final Color bgColor = isDark
            ? AppTheme.backgroundBlack
            : const Color(0xFFF2F2F7);
        final Color surfaceColor = isDark ? AppTheme.surfaceDark : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.grey : Colors.grey.shade600;
        final Color iconColor = isDark ? Colors.white : Colors.black54;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? AppTheme.backgroundBlack : Colors.white,
            elevation: isDark ? 0 : 1,
            title: Text('My lists', style: TextStyle(color: textColor)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () => context.pop(),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.primaryBlue,
            onPressed: _showCreateListDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: MovieManager.instance.getUserListsStream(),
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
                    "You don't have a list yet. Press the + button.",
                    style: TextStyle(color: subTextColor),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final items =
                      data['items'] as List? ?? data['movies'] as List? ?? [];
                  final type = data['type'] ?? 'movies';

                  IconData listIcon = type == 'actor'
                      ? Icons.person
                      : Icons.movie;

                  String? coverImage;
                  if (items.isNotEmpty) {
                    if (items[0]['poster_path'] != null) {
                      coverImage = items[0]['poster_path'];
                    } else if (items[0]['profile_path'] != null) {
                      coverImage = items[0]['profile_path'];
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? Border.all(color: Colors.white10) : null,
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 60,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          image: coverImage != null
                              ? DecorationImage(
                                  image: NetworkImage(coverImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: coverImage == null
                            ? Icon(listIcon, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        data['name'] ?? 'Nameless',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "${items.length} Öğe • ${type == 'actor' ? 'Actor' : 'Movie'}",
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: iconColor),
                        color: surfaceColor,
                        onSelected: (value) {
                          if (value == 'share') _showShareSheet(data, doc.id);
                          if (value == 'rename') {
                            _showRenameDialog(doc.id, data['name']);
                          }
                          if (value == 'delete') _confirmDelete(doc.id);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'share',
                            child: Text(
                              "Share",
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(
                              "Change Name",
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              "Delete",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push(
                          AppRouters.userListDetail,
                          extra: {
                            'listId': doc.id,
                            'listName': data['name'],
                            'items': items,
                            'type': type,
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
