// Dosya: lib/views/profile_view/user_list_detail_view.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListDetailView extends StatefulWidget {
  final String listId;
  final String listName; // Başlangıç için (Stream yüklenene kadar)
  final List items; // Başlangıç için
  final String type; // 'movie', 'movies' veya 'actor'

  const UserListDetailView({
    super.key,
    required this.listId,
    required this.listName,
    required this.items,
    required this.type,
  });

  @override
  State<UserListDetailView> createState() => _UserListDetailViewState();
}

class _UserListDetailViewState extends State<UserListDetailView> {
  // İsim değiştirme penceresi
  void _showRenameDialog(String currentName) {
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
                // Sadece veritabanını güncelle, StreamBuilder ekranı otomatik güncelleyecek
                await MovieManager.instance.renameCustomList(
                  widget.listId,
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

  // Paylaşım penceresi
  void _showShareSheet(String currentListName, int itemCount) {
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
                        final email = data['email'] ?? 'Unknown';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.surfaceDark,
                            child: Text(
                              email[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            email,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Icon(
                            Icons.send,
                            color: AppTheme.primaryBlue,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            final sharedData = {
                              'id': widget.listId,
                              'name': currentListName,
                              'count': itemCount,
                              'type': widget.type,
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null)
      return const Scaffold(
        body: Center(child: Text("Hata: Giriş yapılmamış")),
      );

    // --- BURASI DEĞİŞTİ: ARTIK CANLI DİNLİYORUZ ---
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('lists')
          .doc(widget.listId)
          .snapshots(),
      builder: (context, snapshot) {
        // Yüklenirken veya hata varsa eski veriyi (widget'tan geleni) gösterelim ki ekran boş kalmasın
        String listName = widget.listName;
        List currentItems = widget.items;

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          listName = data['name'] ?? widget.listName;
          // 'items' yoksa 'movies'e bak (eski uyumluluk)
          currentItems =
              data['items'] as List? ?? data['movies'] as List? ?? [];
        } else if (snapshot.connectionState == ConnectionState.active &&
            !snapshot.data!.exists) {
          // Liste silinmişse geri at
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.pop();
          });
          return const SizedBox();
        }

        final bool isPersonList = widget.type == 'actor';

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            backgroundColor: AppTheme.backgroundBlack,
            title: Text(listName, style: const TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: AppTheme.surfaceDark,
                onSelected: (val) {
                  if (val == 'rename') _showRenameDialog(listName);
                  if (val == 'share')
                    _showShareSheet(listName, currentItems.length);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text(
                      "Adını Değiştir",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Text(
                      "Paylaş",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: currentItems.isEmpty
              ? const Center(
                  child: Text(
                    "Bu liste boş.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentItems.length,
                  itemBuilder: (context, index) {
                    final item = currentItems[index] as Map<String, dynamic>;

                    // Verileri güvenli çekme
                    String title = item['title'] ?? item['name'] ?? 'Unknown';
                    String? image = item['poster_path'] ?? item['profile_path'];
                    String? releaseDate =
                        item['release_date']; // Sadece filmlerde olur

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: image != null
                              ? CachedNetworkImage(
                                  imageUrl: image,
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) =>
                                      Container(color: AppTheme.surfaceDark),
                                  errorWidget: (c, u, e) => Container(
                                    color: Colors.grey,
                                    child: const Icon(Icons.error),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 75,
                                  color: Colors.grey,
                                  child: Icon(
                                    isPersonList ? Icons.person : Icons.movie,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: releaseDate != null
                            ? Text(
                                releaseDate,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            // Silme işlemi (Stream sayesinde anlık güncellenecek)
                            await MovieManager.instance
                                .removeMovieFromCustomList(widget.listId, item);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Öğe silindi."),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                        ),
                        onTap: () {
                          // Detay yönlendirmesi
                          if (isPersonList) {
                            context.push(
                              '/person-detail',
                              extra: Person.fromTMDB(item),
                            );
                          } else {
                            context.push(
                              '/movie-detail',
                              extra: Movie.fromMap(item),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
