// Dosya: lib/views/home_view/group_chat_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/models/movie_model.dart'; // Movie modeli eklendi

class GroupChatView extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isCreator;
  final String? groupIconUrl;
  final Movie? sharedMovie; // [YENİ] Taslak film parametresi

  const GroupChatView({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isCreator,
    this.groupIconUrl,
    this.sharedMovie,
  });

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // [YENİ] Taslak ve Reply Durumları
  Movie? _draftMovie;
  Map<String, dynamic>? _replyToMessage;

  @override
  void initState() {
    super.initState();
    // Eğer bir film ile gelindiyse taslağa al
    if (widget.sharedMovie != null) {
      _draftMovie = widget.sharedMovie;
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty && _draftMovie == null) return;

    _msgController.clear();

    final movieToSend = _draftMovie != null
        ? {
            'id': _draftMovie!.id,
            'title': _draftMovie!.title,
            'poster_path': _draftMovie!.poster,
          }
        : null;

    final replyData = _replyToMessage;

    setState(() {
      _draftMovie = null;
      _replyToMessage = null;
    });

    await MovieManager.instance.sendGroupMessage(
      widget.groupId,
      text,
      sharedMovie: movieToSend,
      replyTo: replyData,
    );

    _scrollDown();
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

  void _showEditGroupDialog(String currentName, String currentDesc) {
    final nameCtrl = TextEditingController(text: currentName);
    final descCtrl = TextEditingController(text: currentDesc);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "Grubu Düzenle",
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                labelText: "Grup Adı",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                labelText: "Açıklama",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
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
              if (nameCtrl.text.trim().isNotEmpty) {
                await MovieManager.instance.updateGroupInfo(
                  widget.groupId,
                  nameCtrl.text.trim(),
                  descCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Group information updated.")),
                  );
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markAsSeen(String docId, List<dynamic> seenBy) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myEmail = FirebaseAuth.instance.currentUser?.email;
    if (myUid == null) return;

    final alreadySeen = seenBy.any((e) => e['uid'] == myUid);
    if (!alreadySeen) {
      MovieManager.instance.markGroupMessageAsSeen(
        widget.groupId,
        docId,
        myEmail!.split('@')[0],
      );
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            children: [
              Text(
                "Share",
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachOption(
                    icon: Icons.movie,
                    label: "Find Movie",
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMovieSearchDialog();
                    },
                  ),
                  _buildAttachOption(
                    icon: Icons.list_alt,
                    label: "My Lists",
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMyListsDialog();
                    },
                  ),
                  _buildAttachOption(
                    icon: Icons.favorite,
                    label: "Favorites",
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _shareFavorites();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppTheme.textColor)),
        ],
      ),
    );
  }

  void _showMovieSearchDialog() {
    final searchCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: searchCtrl,
                style: TextStyle(color: AppTheme.textColor),
                decoration: InputDecoration(
                  hintText: "Write the movie's name...",
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: AppTheme.primaryBlue),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("This feature will be added soon!"),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "To share a movie, go to the movie's details page and use the 'Share' button.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [GÜNCELLENDİ] Normal Liste Paylaşımı
  void _showMyListsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text("Select List", style: TextStyle(color: AppTheme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: MovieManager.instance.getUserListsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "You don't have a list.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.list, color: Colors.orange),
                    title: Text(
                      data['name'],
                      style: TextStyle(color: AppTheme.textColor),
                    ),
                    onTap: () {
                      // [DÜZELTME] Yerel fonksiyon ile gönderiyoruz
                      _sendListMessage({
                        'id': docs[index].id,
                        'name': data['name'],
                        'count': (data['items'] as List).length,
                        'type': data['type'] ?? 'movies',
                        'items': data['items'], // İçeriği eklemeyi unutmuyoruz
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

  // [GÜNCELLENDİ] Favori Paylaşımı
  void _shareFavorites() {
    final favMovies = MovieManager.instance.favoriteMovies;
    if (favMovies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your favorites list is empty.")),
      );
      return;
    }

    // Filmleri Map formatına çevir
    final itemsMap = favMovies
        .map(
          (m) => {
            'id': m.id,
            'title': m.title,
            'poster_path': m.poster,
            'overview': m.plot,
            'vote_average': m.rating,
            'release_date': m.releaseDate,
            'genre_ids': m.genres,
          },
        )
        .toList();

    // [DÜZELTME] Artık yerel fonksiyonu kullanıyoruz
    _sendListMessage({
      'id': 'favorites',
      'name': 'My Favorites',
      'count': favMovies.length,
      'type': 'movies',
      'items': itemsMap, // Veriler burada
    });
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.data!.exists) {
                  return const Center(child: Text("Group not found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final members = List<String>.from(data['members'] ?? []);
                final pending = List<String>.from(
                  data['pending_requests'] ?? [],
                );
                final creatorId = data['creator_id'];

                final iconIdx = data['group_icon_id'] ?? 0;
                final iconUrl =
                    MovieManager.instance.groupIcons.length > iconIdx
                    ? MovieManager.instance.groupIcons[iconIdx]
                    : MovieManager.instance.groupIcons[0];

                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                final isAdmin =
                    currentUid != null &&
                    creatorId != null &&
                    currentUid.trim() == creatorId.toString().trim();

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // İkon ve Değiştirme Butonu (Mevcut kodun aynısı)
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(iconUrl),
                                ),
                              ),
                              if (isAdmin)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _showIconPicker();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // [GÜNCELLENDİ] İsim ve Düzenleme Butonu Yan Yana
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              data['name'],
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(
                                Icons.edit_note,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                // Dialog açılınca bottom sheet kapanmasın diye pop yapmıyoruz
                                // İsteğe bağlı olarak pop yapılabilir: Navigator.pop(ctx);
                                _showEditGroupDialog(
                                  data['name'],
                                  data['description'] ?? "",
                                );
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          "${members.length} Member",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),

                      // Açıklama
                      if (data['description'] != null &&
                          data['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              data['description'],
                              style: TextStyle(color: Colors.grey[400]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Grup Silme Butonu (Mevcut kodun aynısı)
                      if (isAdmin) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            foregroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete_forever),
                          label: const Text("Delete Group"),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.surfaceDark,
                                title: const Text(
                                  "Grubu Sil",
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  "Are you sure you want to permanently delete this group?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(c);
                                      Navigator.pop(ctx);
                                      await MovieManager.instance.deleteGroup(
                                        widget.groupId,
                                      );
                                      if (mounted) context.pop();
                                    },
                                    child: const Text(
                                      "Sil",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Üyeler Listesi (Mevcut kodun aynısı)
                      const Divider(color: Colors.white24),
                      Text(
                        "Üyeler",
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...members.map((uid) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) return const SizedBox();
                            final userData =
                                userSnap.data!.data() as Map<String, dynamic>;
                            final email = userData['email'] ?? 'Unknown';
                            final userIconIdx =
                                userData['profile_icon_id'] ?? 0;
                            final userIconUrl =
                                MovieManager.instance.profileIcons.length >
                                    userIconIdx
                                ? MovieManager
                                      .instance
                                      .profileIcons[userIconIdx]
                                : MovieManager.instance.profileIcons[0];
                            final isUserCreator =
                                uid.trim() == creatorId.toString().trim();

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(userIconUrl),
                              ),
                              title: Text(
                                email.split('@')[0],
                                style: TextStyle(color: AppTheme.textColor),
                              ),
                              trailing: isUserCreator
                                  ? const Text(
                                      "Yönetici",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        );
                      }),

                      // Bekleyen İstekler (Mevcut kodun aynısı)
                      if (isAdmin && pending.isNotEmpty) ...[
                        const Divider(color: Colors.white24),
                        const Text(
                          "Bekleyen İstekler",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...pending.map((uid) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .get(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData) return const SizedBox();
                              final userData =
                                  userSnap.data!.data() as Map<String, dynamic>;
                              return ListTile(
                                title: Text(
                                  userData['email'],
                                  style: TextStyle(color: AppTheme.textColor),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => MovieManager.instance
                                      .approveGroupMember(widget.groupId, uid),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- İKON DEĞİŞTİRME MENÜSÜ ---
  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (ctx) => Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Change Group Icon",
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: MovieManager.instance.groupIcons.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // İkonu güncelle
                      MovieManager.instance.updateGroupIcon(
                        widget.groupId,
                        index,
                      );
                      Navigator.pop(ctx); // Penceryi kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("The group icon has been updated."),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: CircleAvatar(
                        radius: 30,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      // AppBar'ı sadeleştiriyoruz, başlık artık body içinde
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            onPressed: _showGroupInfo,
          ),
        ],
      ),
      // Body'yi StreamBuilder ile sarıyoruz ki Header güncel kalsın
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .snapshots(),
        builder: (context, groupSnap) {
          // Grup silindiyse veya veri yoksa güvenli çıkış
          if (!groupSnap.hasData || !groupSnap.data!.exists) {
            return const Center(
              child: Text(
                "The group either doesn't exist or has been deleted.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final groupData = groupSnap.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              // 1. ŞIK GRUP BAŞLIĞI (EN ÜSTTE)
              _buildGroupHeader(groupData),

              // 2. MESAJ LİSTESİ
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getGroupMessagesStream(
                    widget.groupId,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final msg = doc.data() as Map<String, dynamic>;
                        final isMe = msg['sender_id'] == myUid;

                        final seenBy = msg['seen_by'] as List? ?? [];
                        if (!isMe) _markAsSeen(doc.id, seenBy);

                        return _buildGroupMessageBubble(
                          doc.id,
                          msg,
                          isMe,
                          seenBy,
                        );
                      },
                    );
                  },
                ),
              ),

              // 3. REPLY / DRAFT GÖSTERGESİ
              if (_replyToMessage != null || _draftMovie != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: AppTheme.surfaceDark,
                  child: Row(
                    children: [
                      if (_replyToMessage != null) ...[
                        Icon(Icons.reply, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Response: ${_replyToMessage!['sender']}",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                      if (_draftMovie != null) ...[
                        const Icon(Icons.movie, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Added: ${_draftMovie!.title}",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() {
                          _replyToMessage = null;
                          _draftMovie = null;
                        }),
                      ),
                    ],
                  ),
                ),

              // 4. INPUT ALANI
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
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
          );
        },
      ),
    );
  }

  // [YENİ] Mesaj Seçenekleri Menüsü (Tek Tıklama ile Açılır)
  void _showMessageOptions(
    String docId,
    Map<String, dynamic> msg,
    List seenBy,
  ) {
    final senderName = (msg['sender_email'] ?? '').split('@')[0];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Yanıtla
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.blueAccent),
                title: Text(
                  "Reply",
                  style: TextStyle(color: AppTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _replyToMessage = {
                      'id': docId,
                      'sender': senderName,
                      'text': msg['text'] ?? 'Media',
                    };
                  });
                },
              ),
              // 2. Beğen
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.redAccent),
                title: Text(
                  "Like",
                  style: TextStyle(color: AppTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  MovieManager.instance.toggleGroupMessageLike(
                    widget.groupId,
                    docId,
                  );
                },
              ),
              // 3. Görenler
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.green),
                title: Text(
                  "who see",
                  style: TextStyle(color: AppTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSeenByList(seenBy);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // [YENİ] Görenler Listesi Penceresi
  void _showSeenByList(List seenBy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text("who see", style: TextStyle(color: AppTheme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: seenBy.isEmpty
              ? const Center(
                  child: Text(
                    "No one has seen it yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: seenBy.length,
                  itemBuilder: (context, index) {
                    final viewer = seenBy[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                        size: 16,
                      ),
                      title: Text(
                        viewer['name'] ?? 'Unknown',
                        style: TextStyle(color: AppTheme.textColor),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMessageBubble(
    String docId,
    Map<String, dynamic> msg,
    bool isMe,
    List seenBy,
  ) {
    final senderName = (msg['sender_email'] ?? '').split('@')[0];
    final likes = List<String>.from(msg['likes'] ?? []);
    final replyTo = msg['reply_to'] as Map<String, dynamic>?;

    // [YENİ] Tema Kontrolü
    final bool isDark = MovieManager.instance.isDarkMode;

    // --- RENK AYARLARI ---
    // Balon Rengi:
    // Ben (Karanlık): Koyu/Tok Mavi | Ben (Aydınlık): Normal Parlak Mavi
    // O (Karanlık): Koyu Gri        | O (Aydınlık): Açık Gri
    final Color bubbleColor = isMe
        ? (isDark ? const Color(0xFF1565C0) : AppTheme.primaryBlue)
        : (isDark ? AppTheme.surfaceDark : Colors.grey.shade300);

    // Yazı Rengi:
    // Ben: Hep Beyaz
    // O (Karanlık): Beyaz | O (Aydınlık): Siyah
    final Color textColor = isMe
        ? Colors.white
        : (isDark ? AppTheme.textColor : Colors.black87);

    // İsim Rengi (Karşı taraf için)
    final Color nameColor = isDark ? Colors.orange : Colors.deepOrange;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _replyToMessage = {
            'id': docId,
            'sender': senderName,
            'text': msg['text'] ?? 'Media',
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Replying to message..."),
            duration: Duration(seconds: 1),
          ),
        );
      },
      onTap: () {
        _showMessageOptions(docId, msg, seenBy);
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Text(
                    senderName,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Mesaj Kutusu
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                  // Karanlık modda hafif sınır ekleyelim ki karışmasın
                  border: isDark
                      ? Border.all(color: Colors.white10, width: 0.5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // REPLY KUTUSU
                    if (replyTo != null)
                      Container(
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          border: const Border(
                            left: BorderSide(color: Colors.orange, width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyTo['sender'],
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              replyTo['text'] ?? 'Media',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                    if (msg['list_id'] != null) _buildClickableListCard(msg),
                    if (msg['movie_id'] != null) _buildClickableMovieCard(msg),

                    if (msg['text'] != null &&
                        msg['text'].toString().isNotEmpty)
                      Text(
                        msg['text'],
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                  ],
                ),
              ),

              // Alt Bilgiler (Like & Seen)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (likes.isNotEmpty) ...[
                      const Icon(Icons.favorite, color: Colors.red, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        "${likes.length}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isMe && seenBy.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.done_all,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "${seenBy.length}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [GÜNCELLENMİŞ] Tıklanabilir Liste Kartı
  Widget _buildClickableListCard(Map<String, dynamic> msg) {
    return GestureDetector(
      onTap: () {
        // Liste içeriği mesajın içinde var mı?
        if (msg.containsKey('list_items') && msg['list_items'] != null) {
          final items = List<Map<String, dynamic>>.from(msg['list_items']);

          // GÜVENLİ EKRANI AÇ
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SharedListDisplayView(
                title: msg['list_name'] ?? 'Liste',
                items: items,
              ),
            ),
          );
        } else {
          // Eski mesajlar veya veri yoksa
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This list cannot be displayed (Old message)."),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.list_alt, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg['list_name'] ?? 'List',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [GÜNCELLENDİ] Daha Kompakt Grup Başlığı
  Widget _buildGroupHeader(Map<String, dynamic> groupData) {
    final iconIdx = groupData['group_icon_id'] ?? 0;
    final iconUrl = MovieManager.instance.groupIcons.length > iconIdx
        ? MovieManager.instance.groupIcons[iconIdx]
        : MovieManager.instance.groupIcons[0];
    final name = groupData['name'] ?? widget.groupName;
    final desc = groupData['description'] ?? "";

    return Container(
      width: double.infinity,
      // Paddingleri azalttık (Daha yukarı çekildi)
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        // Column yerine Row kullandık (Yatay yerleşim daha az yer kaplar)
        children: [
          CircleAvatar(
            radius: 24, // İkon küçültüldü
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(iconUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 16, // Font küçültüldü
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppTheme.textColor.withValues(alpha: 0.6),
                      fontSize: 12, // Açıklama fontu küçültüldü
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [YENİ] Tıklanabilir Film Kartı
  Widget _buildClickableMovieCard(Map<String, dynamic> msg) {
    return GestureDetector(
      onTap: () {
        // Filmi oluştur ve detaya git
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
        margin: const EdgeInsets.only(bottom: 5),
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
                msg['movie_title'] ?? 'Movie',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [YENİ] Listeyi ve İçeriğini Garantili Kaydetme Fonksiyonu
  Future<void> _sendListMessage(Map<String, dynamic> listData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final msgData = {
      'sender_id': user.uid,
      'sender_email': user.email,
      'text': "Shared a list",
      'created_at': FieldValue.serverTimestamp(),
      'likes': [],
      'seen_by': [],
      'list_id': listData['id'],
      'list_name': listData['name'],
      'list_count': listData['count'],
      'list_type': listData['type'] ?? 'movies',
    };

    // [KRİTİK] Liste içeriğini mesajın içine gömüyoruz
    if (listData.containsKey('items')) {
      msgData['list_items'] = listData['items'];
    }

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add(msgData);

    _scrollDown();
  }
}
// BU KODU DOSYANIN EN ALTINA YAPIŞTIR

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
              child: Text(
                "List is empty",
                style: TextStyle(color: Colors.grey),
              ),
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
                      item['title'] ?? 'Unknown Movie',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: item['vote_average'] != null
                        ? Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['vote_average'].toString(),
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      // Film detayına gitmek için:
                      // final m = Movie.fromMap(item);
                      // context.push('/movie-detail', extra: m);
                    },
                  ),
                );
              },
            ),
    );
  }
}
