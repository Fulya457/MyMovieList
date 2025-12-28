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
  final String listName; // Başlangıç için
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
  // Helper: Mevcut tema durumunu al
  bool get isDark => MovieManager.instance.isDarkMode;
  Color get dialogBg => isDark ? AppTheme.surfaceDark : Colors.white;
  Color get dialogText => isDark ? Colors.white : Colors.black;
  Color get hintColor => isDark ? Colors.grey : Colors.black54;
  Color get inputFill => isDark ? Colors.black26 : Colors.grey.shade200;

  // İsim değiştirme penceresi
  void _showRenameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          "Listeyi Yeniden Adlandır",
          style: TextStyle(color: dialogText),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: dialogText),
          decoration: InputDecoration(
            hintText: "Yeni isim...",
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
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
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
      backgroundColor: isDark ? AppTheme.backgroundBlack : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 500,
          child: Column(
            children: [
              Text(
                "Listeyi Paylaş",
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
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.data!.docs.isEmpty)
                      return Center(
                        child: Text(
                          "Arkadaşın yok.",
                          style: TextStyle(color: hintColor),
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
                            backgroundColor: isDark
                                ? AppTheme.surfaceDark
                                : Colors.grey.shade200,
                            child: Text(
                              email[0].toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          title: Text(
                            email,
                            style: TextStyle(color: dialogText),
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
    // [ÖNEMLİ] Tema değişikliklerini dinlemek için AnimatedBuilder
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
        final Color iconColor = isDark ? Colors.white : Colors.black;

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null)
          return const Scaffold(
            body: Center(child: Text("Hata: Giriş yapılmamış")),
          );

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('lists')
              .doc(widget.listId)
              .snapshots(),
          builder: (context, snapshot) {
            String listName = widget.listName;
            List currentItems = widget.items;

            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              listName = data['name'] ?? widget.listName;
              currentItems =
                  data['items'] as List? ?? data['movies'] as List? ?? [];
            } else if (snapshot.connectionState == ConnectionState.active &&
                !snapshot.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.pop();
              });
              return const SizedBox();
            }

            final bool isPersonList = widget.type == 'actor';

            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: isDark
                    ? AppTheme.backgroundBlack
                    : Colors.white,
                elevation: isDark ? 0 : 1,
                title: Text(listName, style: TextStyle(color: textColor)),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: iconColor),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: iconColor),
                    color: surfaceColor,
                    onSelected: (val) {
                      if (val == 'rename') _showRenameDialog(listName);
                      if (val == 'share')
                        _showShareSheet(listName, currentItems.length);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Text(
                          "Adını Değiştir",
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Text(
                          "Paylaş",
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: currentItems.isEmpty
                  ? Center(
                      child: Text(
                        "Bu liste boş.",
                        style: TextStyle(color: subTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: currentItems.length,
                      itemBuilder: (context, index) {
                        final item =
                            currentItems[index] as Map<String, dynamic>;

                        String title =
                            item['title'] ?? item['name'] ?? 'Unknown';
                        String? image =
                            item['poster_path'] ?? item['profile_path'];
                        String? releaseDate = item['release_date'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: isDark
                                ? Border.all(color: Colors.white10)
                                : null,
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
                            contentPadding: const EdgeInsets.all(10),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: image != null
                                  ? CachedNetworkImage(
                                      imageUrl: image,
                                      width: 50,
                                      height: 75,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(
                                        color: isDark
                                            ? AppTheme.surfaceDark
                                            : Colors.grey.shade300,
                                      ),
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
                                        isPersonList
                                            ? Icons.person
                                            : Icons.movie,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: releaseDate != null
                                ? Text(
                                    releaseDate,
                                    style: TextStyle(
                                      color: subTextColor,
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
                                await MovieManager.instance
                                    .removeMovieFromCustomList(
                                      widget.listId,
                                      item,
                                    );

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
      },
    );
  }
}
