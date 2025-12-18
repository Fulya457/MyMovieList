import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class UserListDetailView extends StatelessWidget {
  final String listId;
  final String listName;
  final List items;
  final String type; // 'movie', 'actor', 'director'

  const UserListDetailView({
    super.key,
    required this.listId,
    required this.listName,
    required this.items,
    required this.type,
  });

  void _shareList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                "Listeyi Paylaş",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getFriendsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(data['email'][0].toUpperCase()),
                          ),
                          title: Text(
                            data['email'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showCommentDialog(
                              context,
                              data['uid'],
                              data['email'],
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

  void _showCommentDialog(
    BuildContext context,
    String targetUid,
    String targetEmail,
  ) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "$targetEmail kişisine gönder",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: commentController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Bir not ekle...",
            filled: true,
            fillColor: Colors.black26,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              MovieManager.instance.sendMessage(
                receiverUid: targetUid,
                text: commentController.text.isEmpty
                    ? "Bir $type listesi paylaştı: $listName"
                    : commentController.text,
                sharedList: {
                  'id': listId,
                  'name': listName,
                  'count': items.length,
                },
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Liste paylaşıldı!")),
              );
            },
            child: const Text("Gönder"),
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
        title: Text(listName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareList(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await MovieManager.instance.deleteCustomList(listId);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                "Bu listede öğe yok.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final itemMap = items[index];
                final imagePath =
                    itemMap['poster_path'] ?? itemMap['profile_path'];
                final title = itemMap['title'] ?? itemMap['name'];

                return ListTile(
                  leading: imagePath != null
                      ? CachedNetworkImage(
                          imageUrl: imagePath,
                          width: 50,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: Colors.grey),
                          errorWidget: (c, u, e) => Icon(
                            type == 'movie' ? Icons.movie : Icons.person,
                            color: Colors.grey,
                          ),
                        )
                      : Icon(
                          type == 'movie' ? Icons.movie : Icons.person,
                          color: Colors.grey,
                        ),
                  title: Text(
                    title ?? 'Bilinmeyen',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await MovieManager.instance.removeMovieFromCustomList(
                        listId,
                        itemMap,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    if (type == 'movie') {
                      context.push(
                        '/movie-detail',
                        extra: Movie.fromMap(itemMap),
                      );
                    } else {
                      context.push(
                        '/person-detail',
                        extra: Person.fromTMDB(itemMap),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
