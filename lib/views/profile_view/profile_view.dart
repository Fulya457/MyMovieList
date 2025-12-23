import 'package:cloud_firestore/cloud_firestore.dart'; // StreamBuilder için gerekli
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  String _getMemberName() {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Kullanıcı';
    if (email.contains('@')) {
      return email.substring(0, email.indexOf('@')).toUpperCase();
    }
    return 'USER';
  }

  // AVATAR SEÇME PENCERESİ
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
              final newPass = passwordController.text.trim();
              
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Şifre en az 6 karakter olmalıdır!"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              try {
                await MovieManager.instance.changePassword(newPass);
                
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Şifre başarıyla değiştirildi."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Hata: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final userName = _getMemberName();

    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        final favCount = MovieManager.instance.favoriteMovies.length;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          body: CustomScrollView(
            slivers: [
              // 1. HEADER
              SliverAppBar(
                expandedHeight: 280,
                backgroundColor: AppTheme.backgroundBlack,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.3),
                          AppTheme.backgroundBlack,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar
                        StreamBuilder<int>(
                          stream: MovieManager.instance.getCurrentUserIconIndex(),
                          builder: (context, snapshot) {
                            final iconIndex = snapshot.data ?? 0;
                            final iconUrl = MovieManager.instance.profileIcons[iconIndex];
                            return GestureDetector(
                              onTap: () => _showAvatarSelection(context),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.primaryBlue, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue.withOpacity(0.4),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundImage: NetworkImage(iconUrl),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        // İsim
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. İSTATİSTİKLER (Row)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context: context,
                        label: "Favoriler", 
                        count: favCount.toString(), 
                        icon: Icons.favorite,
                        onTap: () {
                           // Favorilere tıklandığında ne olacağı (şuan zaten açık sayılır veya bir yere gitmez)
                        },
                      ),
                      
                      StreamBuilder<QuerySnapshot>(
                        stream: MovieManager.instance.getUserListsStream(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatCard(
                            context: context,
                            label: "Listeler", 
                            count: count.toString(), 
                            icon: Icons.list,
                            onTap: () {
                              context.push(AppRouters.userLists);
                            },
                          );
                        },
                      ),
                      
                      // --- CANLI YORUM SAYISI ---
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return _buildStatCard(
                            context: context,
                            label: "Yorumlar", 
                            count: count.toString(), 
                            icon: Icons.comment,
                            onTap: () {
                              context.push(AppRouters.userReviews);
                            },
                          );
                        },
                      ), 
                    ],
                  ),
                ),
              ),

              // 3. SON FAVORİLER (Yatay Liste)
              if (favCount > 0) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      "Son Favorilerim",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: MovieManager.instance.favoriteMovies.length,
                      itemBuilder: (context, index) {
                        final reversedList = MovieManager.instance.favoriteMovies.reversed.toList();
                        final movie = reversedList[index];
                        
                        return GestureDetector(
                          onTap: () => context.push('/movie-detail', extra: movie),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(movie.poster, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  movie.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 4. MENÜ LİSTESİ
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 10),
                    const Text("Hesap Ayarları", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      icon: Icons.people,
                      text: "Arkadaşlarım",
                      color: Colors.purpleAccent,
                      onTap: () => context.push(AppRouters.friends),
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      text: "Bildirimler",
                      color: Colors.orangeAccent,
                      onTap: () => context.push(AppRouters.notifications),
                    ),
                    _buildMenuItem(
                      icon: Icons.rate_review,
                      text: "Değerlendirmelerim",
                      color: Colors.blueAccent,
                      onTap: () => context.push(AppRouters.userReviews),
                    ),
                    _buildMenuItem(
                      icon: Icons.lock_reset,
                      text: "Şifre Değiştir",
                      color: Colors.greenAccent,
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        "Çıkış Yap",
                        style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) context.go(AppRouters.login);
                      },
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widget: İstatistik Kartı
  Widget _buildStatCard({
    required BuildContext context,
    required String label, 
    required String count, 
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Menü Elemanı
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = AppTheme.primaryBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
