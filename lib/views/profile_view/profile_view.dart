// Dosya: lib/views/profile_view/profile_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  String _getMemberName() {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'User';
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
              Text(
                "Choose Profile Avatar",
                style: TextStyle(
                  color: AppTheme.textColor,
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
                            content: Text("Profile avatar updated!"),
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
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "Change Password",
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please enter your current password first.",
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: currentPassController,
              obscureText: true,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                hintText: "Current Password",
                hintStyle: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                filled: true,
                fillColor: MovieManager.instance.isDarkMode
                    ? Colors.black26
                    : Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassController,
              obscureText: true,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                hintText: "New Password",
                hintStyle: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.vpn_key, color: AppTheme.primaryBlue),
                filled: true,
                fillColor: MovieManager.instance.isDarkMode
                    ? Colors.black26
                    : Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              final currentPass = currentPassController.text.trim();
              final newPass = newPassController.text.trim();
              if (currentPass.isEmpty || newPass.isEmpty) return;
              try {
                await MovieManager.instance.changePassword(
                  currentPass,
                  newPass,
                );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password changed successfully."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final userName = _getMemberName();

    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        final favCount = MovieManager.instance.favoriteMovies.length;
        final isDark = MovieManager.instance.isDarkMode;

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          body: CustomScrollView(
            slivers: [
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
                          AppTheme.primaryBlue.withValues(
                            alpha: isDark ? 0.3 : 0.1,
                          ),
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
                          stream: MovieManager.instance
                              .getCurrentUserIconIndex(),
                          builder: (context, snapshot) {
                            final iconIndex = snapshot.data ?? 0;
                            final iconUrl =
                                MovieManager.instance.profileIcons[iconIndex];
                            return GestureDetector(
                              onTap: () => _showAvatarSelection(context),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryBlue,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue
                                              .withValues(alpha: 0.4),
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
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 16,
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
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. İSTATİSTİKLER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context: context,
                        label: "Favorites",
                        count: favCount.toString(),
                        icon: Icons.favorite,
                        onTap: () => context.go(AppRouters.favorites),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: MovieManager.instance.getUserListsStream(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.docs.length
                              : 0;
                          return _buildStatCard(
                            context: context,
                            label: "Lists",
                            count: count.toString(),
                            icon: Icons.list,
                            onTap: () => context.push(AppRouters.userLists),
                          );
                        },
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where(
                              'user_id',
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.docs.length
                              : 0;
                          return _buildStatCard(
                            context: context,
                            label: "Reviews",
                            count: count.toString(),
                            icon: Icons.comment,
                            onTap: () => context.push(AppRouters.userReviews),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 3. SON FAVORİLER (Yatay)
              if (favCount > 0) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      "Latest Favorites",
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                        final reversedList = MovieManager
                            .instance
                            .favoriteMovies
                            .reversed
                            .toList();
                        final movie = reversedList[index];
                        return GestureDetector(
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      movie.poster,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  movie.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTheme.textColor.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 12,
                                  ),
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
                    Text(
                      "Account Settings",
                      style: TextStyle(
                        color: AppTheme.textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bildirim Ayarı
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        title: Text(
                          "Notifications",
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        secondary: Icon(
                          MovieManager.instance.areNotificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: Colors.orangeAccent,
                        ),
                        value: MovieManager.instance.areNotificationsEnabled,
                        activeThumbColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        onChanged: (val) {
                          MovieManager.instance.toggleNotifications(val);
                        },
                      ),
                    ),

                    _buildMenuItem(
                      icon: Icons.people,
                      text: "Friends",
                      color: Colors.purpleAccent,
                      onTap: () => context.push(AppRouters.friends),
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      text: "Communication Center",
                      color: Colors.orangeAccent,
                      onTap: () => context.push(AppRouters.notifications),
                    ),
                    _buildMenuItem(
                      icon: Icons.rate_review,
                      text: "My Reviews",
                      color: Colors.blueAccent,
                      onTap: () => context.push(AppRouters.userReviews),
                    ),
                    _buildMenuItem(
                      icon: Icons.lock_reset,
                      text: "Change Password",
                      color: Colors.greenAccent,
                      onTap: () => _showChangePasswordDialog(context),
                    ),

                    // --- TEMA DEĞİŞTİR BUTONU ---
                    _buildMenuItem(
                      icon: isDark ? Icons.light_mode : Icons.dark_mode,
                      text: isDark ? "Light Mode" : "Dark Mode",
                      color: isDark ? Colors.amber : Colors.indigo,
                      onTap: () {
                        MovieManager.instance.toggleTheme();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isDark
                                  ? "Switched to Light Mode!"
                                  : "Switched to Dark Mode!",
                            ),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
          border: Border.all(color: AppTheme.textColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textColor.withValues(alpha: 0.6),
                fontSize: 12,
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
    Color color = Colors.blue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          text,
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppTheme.textColor.withValues(alpha: 0.4),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
