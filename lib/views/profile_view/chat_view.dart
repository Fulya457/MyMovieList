import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/services/social_service.dart';

class ChatView extends StatefulWidget {
  final Map<String, dynamic> extras; // {uid, email}
  const ChatView({super.key, required this.extras});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // HATA KORUMASI: Extras null gelirse patlamasın
    final otherUid = widget.extras['targetUid'] ?? widget.extras['uid'] ?? '';
    final otherEmail =
        widget.extras['targetEmail'] ?? widget.extras['email'] ?? 'Kullanıcı';
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(otherEmail, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: MovieManager.instance.getMessagesStream(otherUid),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['sender_id'] == myUid;
                    return _buildMessageItem(data, isMe, context);
                  },
                );
              },
            ),
          ),
          _buildInputArea(otherUid),
        ],
      ),
    );
  }

  Widget _buildInputArea(String receiverUid) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Mesaj yaz...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primaryBlue),
            onPressed: () {
              if (_msgController.text.trim().isNotEmpty) {
                MovieManager.instance.sendMessage(
                  receiverUid: receiverUid,
                  text: _msgController.text.trim(),
                );
                _msgController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    Map<String, dynamic> data,
    bool isMe,
    BuildContext context,
  ) {
    // HATA KORUMASI: Null check yapıyoruz
    final hasMovie = data['movie_id'] != null;
    final hasList = data['list_id'] != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryBlue : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FİLM KARTI ---
            if (hasMovie)
              GestureDetector(
                onTap: () {
                  // HATA KORUMASI: Tüm string alanlara (?? '') ekledik
                  final movie = Movie(
                    id: data['movie_id'] ?? 0,
                    title: data['movie_title'] ?? 'Bilinmeyen Film',
                    rating: 0.0,
                    poster: data['poster_path'] ?? '',
                    genres: [],
                    genreIds: [],
                    plot: '',
                  );
                  context.push('/movie-detail', extra: movie);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // HATA KORUMASI: Resim yolu boşsa gösterme
                      if (data['poster_path'] != null &&
                          data['poster_path'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            data['poster_path'],
                            width: 40,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.movie, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data['movie_title'] ?? 'Bilinmeyen',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // --- LİSTE KARTI ---
            if (hasList)
              GestureDetector(
                onTap: () => _showSharedListDialog(context, data),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['list_name'] ?? 'Liste',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${data['list_count'] ?? 0} öğe",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // --- NORMAL MESAJ METNİ ---
            // HATA KORUMASI: Text widget asla null almaz
            if (data['text'] != null && data['text'].toString().isNotEmpty)
              Text(
                data['text'].toString(),
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  void _showSharedListDialog(
    BuildContext context,
    Map<String, dynamic> msgData,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 500,
          child: Column(
            children: [
              Text(
                "Paylaşılan Liste: ${msgData['list_name'] ?? 'Liste'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: SocialService.instance.fetchListItems(
                    msgData['sender_id'] ?? '',
                    msgData['list_id'] ?? '',
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final items = snapshot.data!;
                    if (items.isEmpty)
                      return const Center(
                        child: Text(
                          "Bu liste boş.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        // HATA KORUMASI: Null Check
                        final name =
                            item['title'] ?? item['name'] ?? 'Bilinmeyen';
                        final img = item['poster_path'] ?? item['profile_path'];

                        return ListTile(
                          leading: (img != null && img.toString().isNotEmpty)
                              ? Image.network(
                                  img,
                                  width: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.movie,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(Icons.movie, color: Colors.grey),
                          title: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  "Listelerime Kaydet",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  final items = await SocialService.instance.fetchListItems(
                    msgData['sender_id'] ?? '',
                    msgData['list_id'] ?? '',
                  );
                  if (items.isNotEmpty) {
                    String type = 'movie';
                    if (items[0].containsKey('name') &&
                        !items[0].containsKey('title'))
                      type = 'actor';

                    await SocialService.instance.importListFromUser(
                      msgData['list_name'] ?? 'Kopyalanan Liste',
                      items,
                      type,
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Liste başarıyla kaydedildi!"),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
