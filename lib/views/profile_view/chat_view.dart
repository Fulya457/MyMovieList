// Dosya: lib/views/profile_view/chat_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/services/social_service.dart';

class ChatView extends StatefulWidget {
  final Map<String, dynamic> extras;
  const ChatView({super.key, required this.extras});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _attachedList;
  Movie? _attachedMovie;
  Map<String, dynamic>? _replyToMessage;

  late String chatId;
  late String myUid;
  late String targetUid;

  @override
  void initState() {
    super.initState();
    myUid = FirebaseAuth.instance.currentUser!.uid;
    targetUid = widget.extras['targetUid'] ?? widget.extras['uid'];

    final List<String> ids = [myUid, targetUid];
    ids.sort();
    chatId = ids.join("_");

    if (widget.extras.containsKey('sharedList')) {
      _attachedList = widget.extras['sharedList'];
    }
    if (widget.extras.containsKey('sharedMovie')) {
      _attachedMovie = widget.extras['sharedMovie'] as Movie;
    }

    MovieManager.instance.enterChat(targetUid);
  }

  @override
  void dispose() {
    MovieManager.instance.exitChat();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();

    if (text.isEmpty && _attachedList == null && _attachedMovie == null) return;

    _msgController.clear();

    Map<String, dynamic>? movieData;
    if (_attachedMovie != null) {
      movieData = {
        'id': _attachedMovie!.id,
        'title': _attachedMovie!.title,
        'poster_path': _attachedMovie!.poster,
        'overview': _attachedMovie!.plot,
        'release_date': _attachedMovie!.releaseDate,
        'vote_average': _attachedMovie!.rating,
      };
    }

    Map<String, dynamic>? listData = _attachedList;

    final replyData = _replyToMessage;

    setState(() {
      _attachedList = null;
      _attachedMovie = null;
      _replyToMessage = null;
    });

    final msgData = {
      'sender_id': myUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    };

    if (movieData != null) {
      msgData['movie_id'] = movieData['id'];
      msgData['movie_title'] = movieData['title'];
      msgData['poster_path'] = movieData['poster_path'];
    }

    if (listData != null) {
      _sendListMessage(listData, text.isEmpty ? "Shared a list" : text);
      return;
    }

    if (replyData != null) {
      msgData['reply_to'] = replyData;
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(msgData);

    _updateLastMessage(text.isNotEmpty ? text : "Media");
    _scrollDown();
  }

  Future<void> _sendListMessage(
    Map<String, dynamic> listData, [
    String? text,
  ]) async {
    final msgData = {
      'sender_id': myUid,
      'text': text ?? "Shared a list",
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
      'list_id': listData['id'],
      'list_name': listData['list_name'] ?? listData['name'],
      'list_count': listData['count'],
      'list_type': listData['type'] ?? 'movies',
    };

    if (listData.containsKey('items')) {
      msgData['list_items'] = listData['items'];
    } else if (listData.containsKey('list_items')) {
      msgData['list_items'] = listData['list_items'];
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(msgData);

    _updateLastMessage("Shared a list");
    _scrollDown();
  }

  Future<void> _updateLastMessage(String text) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'users': [myUid, targetUid],
      'last_message': text,
      'last_message_time': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _shareFavorites() {
    final favMovies = MovieManager.instance.favoriteMovies;
    if (favMovies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your favorites list is empty.")),
      );
      return;
    }

    final itemsMap = favMovies
        .map(
          (m) => {
            'id': m.id,
            'title': m.title,
            'poster_path': m.poster,
            'overview': m.plot,
            'vote_average': m.rating,
            'release_date': m.releaseDate,
          },
        )
        .toList();

    _sendListMessage({
      'id': 'favorites',
      'name': 'My Favorites',
      'count': favMovies.length,
      'type': 'movies',
      'items': itemsMap,
    });
  }

  void _importList(
    Map<String, dynamic> listData,
    String originalOwnerId,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Copying list...")));
      final items = await SocialService.instance.fetchListItems(
        originalOwnerId,
        listData['list_id'],
      );
      if (items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("The list is empty.")));
        return;
      }
      await SocialService.instance.importListFromUser(
        listData['list_name'],
        items,
        listData['type'] ?? 'movies',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Saved!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error occurred.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
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
              displayName = (data['email'] ?? '')
                  .toString()
                  .split('@')[0]
                  .toUpperCase();
              final idx = data['profile_icon_id'] ?? 0;
              if (idx < MovieManager.instance.profileIcons.length) {
                iconUrl = MovieManager.instance.profileIcons[idx];
              }
            } else {
              displayName = (widget.extras['targetEmail'] ?? '')
                  .toString()
                  .split('@')[0]
                  .toUpperCase();
            }
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: iconUrl != null
                      ? NetworkImage(iconUrl)
                      : null,
                  child: iconUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Text(
                  displayName,
                  style: TextStyle(fontSize: 16, color: AppTheme.textColor),
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
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    return _buildMessageBubble(
                      docs[index].id,
                      msg,
                      msg['sender_id'] == myUid,
                    );
                  },
                );
              },
            ),
          ),

          if (_replyToMessage != null ||
              _attachedMovie != null ||
              _attachedList != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppTheme.surfaceDark,
              child: Row(
                children: [
                  if (_replyToMessage != null)
                    Expanded(
                      child: Text(
                        "Yanıt: ${_replyToMessage!['text']}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (_attachedMovie != null)
                    Expanded(
                      child: Text(
                        "Ekli: ${_attachedMovie!.title}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (_attachedList != null)
                    Expanded(
                      child: Text(
                        "Ekli: ${_attachedList!['name']}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() {
                      _replyToMessage = null;
                      _attachedMovie = null;
                      _attachedList = null;
                    }),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(10),
            color: AppTheme.backgroundBlack,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _showAttachmentMenu,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: TextStyle(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      hintText: "Message...",
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String docId,
    Map<String, dynamic> msg,
    bool isMe,
  ) {
    final bool isDark = MovieManager.instance.isDarkMode;

    final Color bubbleColor = isMe
        ? (isDark ? const Color(0xFF1565C0) : AppTheme.primaryBlue)
        : (isDark ? AppTheme.surfaceDark : Colors.grey.shade300);

    final Color textColor = isMe
        ? Colors.white
        : (isDark ? AppTheme.textColor : Colors.black87);

    final replyTo = msg['reply_to'] as Map<String, dynamic>?;

    return GestureDetector(
      onLongPress: () => setState(
        () => _replyToMessage = {
          'id': docId,
          'text': msg['text'] ?? 'Media',
          'sender': isMe ? 'Ben' : 'User',
        },
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (replyTo != null)
                Container(
                  padding: const EdgeInsets.all(5),
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1), // Hafif karartma
                    border: const Border(
                      left: BorderSide(color: Colors.orange, width: 3),
                    ),
                  ),
                  child: Text(
                    replyTo['text'] ?? '',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7), // Yazı rengine uyumlu
                      fontSize: 10,
                    ),
                    maxLines: 1,
                  ),
                ),

              if (msg['list_id'] != null)
                _buildClickableListCard(msg, isMe, textColor),
              if (msg['movie_id'] != null)
                _buildClickableMovieCard(msg, isMe, textColor),

              if (msg['text'] != null && msg['text'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    msg['text'],
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableListCard(
    Map<String, dynamic> msg,
    bool isMe,
    Color textColor,
  ) {
    final bool isFavorites = msg['list_id'] == 'favorites';
    return GestureDetector(
      onTap: () {
        if (msg.containsKey('list_items') && msg['list_items'] != null) {
          final items = List<Map<String, dynamic>>.from(msg['list_items']);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SharedListDisplayView(
                title: msg['list_name'] ?? 'Liste',
                items: items,
              ),
            ),
          );
        } else if (!isFavorites) {
          context.push(
            AppRouters.userListDetail,
            extra: {
              'listId': msg['list_id'],
              'listName': msg['list_name'],
              'items': [],
              'type': msg['list_type'] ?? 'movies',
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bu eski bir paylaşım, görüntülenemiyor."),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
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
                  ),
                ),
              ],
            ),
            Text(
              "${msg['list_count'] ?? 0} Öğe",
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
            ),
            if (!isMe && !isFavorites) ...[
              const SizedBox(height: 5),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  minimumSize: const Size.fromHeight(30),
                ),
                onPressed: () => _importList(msg, msg['sender_id']),
                child: const Text(
                  "Kaydet",
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClickableMovieCard(
    Map<String, dynamic> msg,
    bool isMe,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () {
        final m = Movie.fromMap({
          'id': msg['movie_id'],
          'title': msg['movie_title'],
          'poster_path': msg['poster_path'],
          'overview': '',
          'release_date': '',
          'vote_average': 0.0,
          'genre_ids': [],
        });
        context.push('/movie-detail', extra: m);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.movie, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg['movie_title'] ?? 'Film',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _iconBtn(Icons.movie, "Film", Colors.blue, () {
              Navigator.pop(ctx);
              _showMovieSearchDialog();
            }),
            _iconBtn(Icons.list, "Liste", Colors.orange, () {
              Navigator.pop(ctx);
              _showMyListsDialog();
            }),
            _iconBtn(Icons.favorite, "Fav", Colors.red, () {
              Navigator.pop(ctx);
              _shareFavorites();
            }),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData i, String l, Color c, VoidCallback t) =>
      GestureDetector(
        onTap: t,
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: c.withOpacity(0.2),
              child: Icon(i, color: c),
            ),
            Text(l, style: TextStyle(color: AppTheme.textColor)),
          ],
        ),
      );
  void _showMovieSearchDialog() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Yakında eklenecek")));
  }

  void _showMyListsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text("Liste Seç", style: TextStyle(color: AppTheme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: MovieManager.instance.getUserListsStream(),
            builder: (c, s) {
              if (!s.hasData) return const CircularProgressIndicator();
              final d = s.data!.docs;
              return ListView.builder(
                itemCount: d.length,
                itemBuilder: (c, i) {
                  final data = d[i].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(
                      data['name'],
                      style: TextStyle(color: AppTheme.textColor),
                    ),
                    onTap: () {
                      _sendListMessage({
                        'id': d[i].id,
                        'name': data['name'],
                        'count': (data['items'] as List).length,
                        'type': data['type'],
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class SharedListDisplayView extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  const SharedListDisplayView({
    super.key,
    required this.title,
    required this.items,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(title, style: TextStyle(color: AppTheme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text("Liste boş", style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = items[index];
                final posterPath = item['poster_path'];
                return Card(
                  color: AppTheme.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: posterPath.startsWith('http')
                                ? posterPath
                                : 'https://image.tmdb.org/t/p/w200$posterPath',
                            width: 50,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.movie, color: Colors.grey),
                          )
                        : const Icon(Icons.movie, color: Colors.grey, size: 40),
                    title: Text(
                      item['title'] ?? 'Film',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      final m = Movie.fromMap(item);
                      context.push('/movie-detail', extra: m);
                    },
                  ),
                );
              },
            ),
    );
  }
}
