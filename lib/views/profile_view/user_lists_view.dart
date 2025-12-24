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
              backgroundColor: AppTheme.surfaceDark,
              title: const Text(
                "Yeni Liste Oluştur",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Liste Adı...",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Liste Türü",
                      labelStyle: TextStyle(color: AppTheme.primaryBlue),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'movies',
                        child: Text("Film Listesi"),
                      ),
                      DropdownMenuItem(
                        value: 'actor',
                        child: Text("Kişi Listesi"),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedType = value!),
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
                      await MovieManager.instance.createCustomList(
                        nameController.text.trim(),
                        selectedType,
                      );
                      if (mounted) Navigator.pop(ctx);
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
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          "Listeyi Yeniden Adlandır",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Yeni isim..."),
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
              if (controller.text.trim().isNotEmpty) {
                await MovieManager.instance.renameCustomList(
                  listId,
                  controller.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- PAYLAŞMA ---
  void _showShareSheet(Map<String, dynamic> listData, String listId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
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
              const Text(
                "Listeyi Paylaş",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getFriendsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.data!.docs.isEmpty)
                      return const Center(
                        child: Text(
                          "Arkadaşın yok.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.surfaceDark,
                            child: Text(
                              (data['email'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            data['email'] ?? '',
                            style: const TextStyle(color: Colors.white),
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

  // --- SİLME (ANINDA GÜNCELLEME İÇİN DÜZENLENDİ) ---
  void _confirmDelete(String listId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          "Listeyi Sil?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Bu işlem geri alınamaz.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              // 1. Önce Dialog'u kapat (Hata olmaması için)
              Navigator.pop(ctx);

              // 2. Silme işlemini başlat
              // StreamBuilder Firestore'u dinlediği için silindiği an UI otomatik güncellenecek
              await MovieManager.instance.deleteCustomList(listId);

              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Liste silindi.")));
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        title: const Text('Listelerim', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showCreateListDialog,
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
            return const Center(
              child: Text(
                "Henüz bir listen yok. + butonuna bas.",
                style: TextStyle(color: Colors.grey),
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

              IconData listIcon = type == 'actor' ? Icons.person : Icons.movie;

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
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black26,
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
                    data['name'] ?? 'İsimsiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "${items.length} Öğe • ${type == 'actor' ? 'Kişi' : 'Film'}",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: AppTheme.surfaceDark,
                    onSelected: (value) {
                      if (value == 'share') _showShareSheet(data, doc.id);
                      if (value == 'rename')
                        _showRenameDialog(doc.id, data['name']);
                      if (value == 'delete') _confirmDelete(doc.id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Text(
                          "Paylaş",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text(
                          "Adını Değiştir",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          "Sil",
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
  }
}
