import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class ChatView extends StatefulWidget {
  final String targetUid;
  final String targetEmail;
  final Movie? sharedMovie; // Opsiyonel: Eğer film paylaşılıyorsa dolu gelir

  const ChatView({
    super.key,
    required this.targetUid,
    required this.targetEmail,
    this.sharedMovie,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Eğer film paylaşılıyorsa, otomatik bir mesaj taslağı oluşturabiliriz
    if (widget.sharedMovie != null) {
      _messageController.text = "Bu filmi izlemelisin! 🎬";
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && widget.sharedMovie == null) return;

    MovieManager.instance.sendMessage(
      receiverUid: widget.targetUid,
      text: text,
      sharedMovie: widget.sharedMovie, // Filmi parametre olarak geçiyoruz
    );

    _messageController.clear();
    // Film gönderildikten sonra sayfayı kapatabilir veya film modundan çıkabiliriz.
    // Şimdilik sadece text temizliyoruz. Eğer paylaşım yaptıysak geri dönmek mantıklı olabilir:
    if (widget.sharedMovie != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Film önerildi!")));
      context.pop(); // Sohbetten çık
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(widget.targetEmail, style: const TextStyle(fontSize: 16)),
        backgroundColor: AppTheme.backgroundBlack,
      ),
      body: Column(
        children: [
          // MESAJ LİSTESİ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: MovieManager.instance.getMessagesStream(widget.targetUid),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // En yeni mesaj en altta (klavye üstü)
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['sender_id'] == currentUid;

                    // Film Verisi var mı?
                    final String? movieTitle = data['movie_title'];
                    final String? poster = data['poster_path'];
                    final int? movieId = data['movie_id'];

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.primaryBlue
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // EĞER MESAJDA FİLM VARSA KART GÖSTER
                            if (movieTitle != null)
                              GestureDetector(
                                onTap: () async {
                                  // Tıklayınca filme git
                                  if (movieId != null) {
                                    final movie = await MovieManager.instance
                                        .getMovieById(movieId);
                                    if (movie != null && context.mounted) {
                                      context.push(
                                        '/movie-detail',
                                        extra: movie,
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      if (poster != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            poster,
                                            width: 40,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          movieTitle,
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

                            if (data['text'] != null &&
                                data['text'].toString().isNotEmpty)
                              Text(
                                data['text'],
                                style: const TextStyle(color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- TASLAK ALANI (Eğer film paylaşılıyorsa burada gözükür) ---
          if (widget.sharedMovie != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[900],
              child: Row(
                children: [
                  const Icon(Icons.share, color: Colors.amber),
                  const SizedBox(width: 10),
                  Text(
                    "Paylaşılıyor: ${widget.sharedMovie!.title}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => context.pop(), // Vazgeç
                  ),
                ],
              ),
            ),

          // GİRİŞ ALANI
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Mesaj yaz...",
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
