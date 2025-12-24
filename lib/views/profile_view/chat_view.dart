// Dosya: lib/views/profile_view/chat_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/services/social_service.dart';

class ChatView extends StatefulWidget {
  final Map<String, dynamic> extras; // {targetUid, targetEmail, sharedList?}
  const ChatView({super.key, required this.extras});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _attachedList;

  @override
  void initState() {
    super.initState();
    if (widget.extras.containsKey('sharedList')) {
      _attachedList = widget.extras['sharedList'];
    }
  }

  // İsim Formatlayıcı (ahmet@gmail.com -> AHMET)
  String _formatName(String email) {
    if (email.contains('@')) {
      return email.split('@')[0].toUpperCase();
    }
    return email.toUpperCase();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty && _attachedList == null) return;

    final targetUid = widget.extras['targetUid'] ?? widget.extras['uid'];

    _msgController.clear();

    await MovieManager.instance.sendMessage(
      receiverUid: targetUid,
      text: text.isEmpty
          ? (_attachedList != null
                ? "Bir liste paylaştı"
                : "Bir içerik paylaştı")
          : text,
      sharedList: _attachedList,
    );

    setState(() {
      _attachedList = null;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _importList(
    Map<String, dynamic> listData,
    String originalOwnerId,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Liste kopyalanıyor...")));
      final items = await SocialService.instance.fetchListItems(
        originalOwnerId,
        listData['list_id'],
      );

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu liste boş veya silinmiş.")),
        );
        return;
      }

      await SocialService.instance.importListFromUser(
        listData['list_name'],
        items,
        listData['type'] ?? 'movies',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Liste başarıyla kaydedildi!")),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Hata oluştu.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetUid = widget.extras['targetUid'] ?? widget.extras['uid'];
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    // [DÜZELTME 1]: Tema değişimini dinlemek için AnimatedBuilder eklendi
    return AnimatedBuilder(
      animation: MovieManager.instance,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceDark,
            iconTheme: IconThemeData(
              color: AppTheme.textColor,
            ), // İkon rengi düzeltildi
            titleSpacing: 0,
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(targetUid)
                  .snapshots(),
              builder: (context, snapshot) {
                String displayName = "Kullanıcı";
                String? iconUrl;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final email = data['email'] ?? '';
                  displayName = _formatName(email);

                  final iconIndex = data['profile_icon_id'] ?? 0;
                  if (iconIndex >= 0 &&
                      iconIndex < MovieManager.instance.profileIcons.length) {
                    iconUrl = MovieManager.instance.profileIcons[iconIndex];
                  }
                } else {
                  final email =
                      widget.extras['targetEmail'] ??
                      widget.extras['email'] ??
                      '';
                  displayName = _formatName(email);
                }

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      backgroundImage: iconUrl != null
                          ? NetworkImage(iconUrl)
                          : null,
                      child: iconUrl == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            AppTheme.textColor, // Başlık rengi dinamik yapıldı
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getMessagesStream(targetUid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final msg = docs[index].data() as Map<String, dynamic>;
                        final isMe = msg['sender_id'] == myUid;

                        // [DÜZELTME 2]: Mesaj baloncuğunu ayrı metoda taşıdık veya burada düzelttik
                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  },
                ),
              ),

              if (_attachedList != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppTheme.surfaceDark,
                  child: Row(
                    children: [
                      Icon(Icons.attachment, color: AppTheme.primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Liste Eklendi:",
                              style: TextStyle(
                                color: AppTheme.textColor.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _attachedList!['name'],
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () => setState(() => _attachedList = null),
                      ),
                    ],
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(10),
                color: AppTheme.backgroundBlack,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style: TextStyle(
                          color: AppTheme.textColor,
                        ), // Yazılan yazı rengi
                        decoration: InputDecoration(
                          hintText: "Mesaj yaz...",
                          hintStyle: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
      },
    );
  }

  // YENİ METOD: Mesaj Baloncuğu Oluşturucu
  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    // [DÜZELTME 3]: Yazı rengi mantığı
    // Eğer benim mesajımsa (Mavi zemin) -> Beyaz yazı
    // Eğer arkadaşın mesajıysa (Yüzey rengi zemin) -> Tema yazı rengi (Aydınlıkta Siyah, Karanlıkta Beyaz)
    final Color textColor = isMe ? Colors.white : AppTheme.textColor;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryBlue : AppTheme.surfaceDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. LİSTE PAYLAŞIMI
            if (msg.containsKey('list_id') && msg['list_id'] != null)
              _buildSharedListCard(msg, isMe, textColor),

            // 2. FİLM PAYLAŞIMI
            if (msg.containsKey('movie_id') &&
                msg['movie_id'] != null &&
                msg['movie_id'] != 0)
              _buildSharedMovieCard(msg, isMe, textColor),

            // 3. MESAJ METNİ
            if (msg['text'] != null && msg['text'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  msg['text'],
                  style: TextStyle(
                    color: textColor, // Düzeltilen renk
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedListCard(
    Map<String, dynamic> msg,
    bool isMe,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // İçerik kartı rengini hafif farklılaştırıyoruz
        color: isMe
            ? Colors.black26
            : AppTheme.backgroundBlack.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: textColor, size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  msg['list_name'] ?? 'Liste',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${msg['list_count'] ?? 0} Öğe",
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (!isMe)
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.primaryBlue, // Buton rengi belirgin olsun
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => _importList(msg, msg['sender_id']),
                child: const Text(
                  "Listelerime Kaydet",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSharedMovieCard(
    Map<String, dynamic> msg,
    bool isMe,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () {
        final movieMap = {
          'id': msg['movie_id'],
          'title': msg['movie_title'] ?? 'Unknown',
          'poster_path': msg['poster_path'],
          'overview': '',
          'release_date': '',
          'vote_average': 0.0,
          'genre_ids': [],
        };
        final movie = Movie.fromMap(movieMap);
        context.push('/movie-detail', extra: movie);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: 150,
        decoration: BoxDecoration(
          color: isMe
              ? Colors.black26
              : AppTheme.backgroundBlack.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: msg['poster_path'] != null
                  ? CachedNetworkImage(
                      imageUrl: msg['poster_path'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey),
                    )
                  : Container(
                      height: 100,
                      color: Colors.grey,
                      child: const Icon(Icons.movie),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['movie_title'] ?? 'Film',
                    style: TextStyle(
                      color: textColor, // Düzeltilen renk
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Film Önerisi",
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
