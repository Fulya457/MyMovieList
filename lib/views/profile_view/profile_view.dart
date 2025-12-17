import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // EKLENDİ
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:cached_network_image/cached_network_image.dart'; // EKLENDİ

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  String _getMemberName() {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Kullanıcı';
    if (email.contains('@')) {
      return email.substring(0, email.indexOf('@')).toUpperCase();
    }
    return 'USER';
  }

  void _showAvatarSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text(
                "Profil Avatarını Seç",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: MovieManager.instance.profileIcons.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        MovieManager.instance.updateProfileIcon(index);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profil fotoğrafı güncellendi!"),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white10,
                        backgroundImage: NetworkImage(
                          MovieManager.instance.profileIcons[index],
                        ),
                      ),
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

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          "Şifre Değiştir",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Yeni Şifre",
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              try {
                await MovieManager.instance.changePassword(
                  passwordController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Şifre başarıyla değiştirildi."),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LİSTE OLUŞTURMA DİYALOGU ---
  void _showCreateListDialog(BuildContext context) {
    final TextEditingController listNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          "Yeni Liste Oluştur",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: listNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Liste Adı (Örn: Korku Gecesi)",
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              if (listNameController.text.isNotEmpty) {
                await MovieManager.instance.createCustomList(
                  listNameController.text.trim(),
                );
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Oluştur", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LİSTE DETAY SAYFASI (Modal olarak açılır) ---
  void _openListDetail(
    BuildContext context,
    String listId,
    String listName,
    List movies,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _UserListDetailView(
          listId: listId,
          listName: listName,
          movies: movies,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final userName = _getMemberName();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  StreamBuilder<int>(
                    stream: MovieManager.instance.getCurrentUserIconIndex(),
                    builder: (context, snapshot) {
                      final iconIndex = snapshot.data ?? 0;
                      final iconUrl =
                          MovieManager.instance.profileIcons[iconIndex];

                      return GestureDetector(
                        onTap: () => _showAvatarSelection(context),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryBlue.withOpacity(
                                0.2,
                              ),
                              backgroundImage: NetworkImage(iconUrl),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- LİSTELERİM BÖLÜMÜ ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Listelerim",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.primaryBlue,
                  ),
                  onPressed: () => _showCreateListDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: MovieManager.instance.getUserListsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty)
                  return const Text(
                    "Henüz bir listen yok.",
                    style: TextStyle(color: Colors.grey),
                  );

                return SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final movies = data['movies'] as List? ?? [];
                      // Kapak resmi olarak ilk filmin posterini al
                      String coverImage = movies.isNotEmpty
                          ? movies.first['poster_path']
                          : '';

                      return GestureDetector(
                        onTap: () => _openListDetail(
                          context,
                          docs[index].id,
                          data['name'],
                          movies,
                        ),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            image: coverImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(coverImage),
                                    fit: BoxFit.cover,
                                    opacity: 0.6,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                data['name'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // ---------------------------
            _buildMenuItem(
              icon: Icons.people,
              text: "Arkadaşlarım",
              onTap: () => context.push(AppRouters.friends),
            ),
            _buildMenuItem(
              icon: Icons.notifications,
              text: "Bildirim Geçmişi",
              onTap: () => context.push(AppRouters.notifications),
            ),
            _buildMenuItem(
              icon: Icons.rate_review,
              text: "Değerlendirmelerim",
              onTap: () => context.push(AppRouters.userReviews),
            ),
            _buildMenuItem(
              icon: Icons.lock_reset,
              text: "Şifre Değiştir",
              onTap: () => _showChangePasswordDialog(context),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Çıkış Yap",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go(AppRouters.login);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(text, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

// --- LİSTE DETAY VE PAYLAŞMA EKRANI ---
class _UserListDetailView extends StatelessWidget {
  final String listId;
  final String listName;
  final List movies;

  const _UserListDetailView({
    required this.listId,
    required this.listName,
    required this.movies,
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
                            // Listeyi paylaşma fonksiyonunu çağır
                            // Bunu ChatView'a gitmeden direkt mesaj olarak atıyoruz
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
                    ? "Bir liste paylaştı: $listName"
                    : commentController.text,
                sharedList: {
                  'id': listId,
                  'name': listName,
                  'count': movies.length,
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
      body: movies.isEmpty
          ? const Center(
              child: Text(
                "Bu listede film yok.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movieMap = movies[index];
                return ListTile(
                  leading: CachedNetworkImage(
                    imageUrl: movieMap['poster_path'],
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    movieMap['title'],
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
                        movieMap,
                      );
                      // Ekranı güncellemek için geri çıkıp girmesi gerekebilir veya stream kullanabiliriz
                      // Basitlik adına burada bırakıyoruz, gerçek zamanlı güncelleme için StreamBuilder kullanılmalıydı.
                      if (context.mounted)
                        Navigator.pop(
                          context,
                        ); // Listeyi yenilemek için kapatıyoruz
                    },
                  ),
                );
              },
            ),
    );
  }
}
