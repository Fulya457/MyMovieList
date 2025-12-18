import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

// Yeni Widget'ları Import Et
import 'package:mymovielist/views/profile_view/widgets/profile_header.dart';
import 'package:mymovielist/views/profile_view/widgets/profile_menu_item.dart';
import 'package:mymovielist/views/profile_view/user_list_detail_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _selectedListType = 'movie'; // 'movie', 'actor', 'director'

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

  void _showCreateListDialog(BuildContext context) {
    final TextEditingController listNameController = TextEditingController();
    String tempType = _selectedListType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text(
              "Yeni Liste Oluştur",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: listNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Liste Adı (Örn: En İyi Komediler)",
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: tempType,
                  dropdownColor: AppTheme.surfaceDark,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  underline: Container(height: 1, color: AppTheme.primaryBlue),
                  items: const [
                    DropdownMenuItem(
                      value: 'movie',
                      child: Text("Film Listesi"),
                    ),
                    DropdownMenuItem(
                      value: 'actor',
                      child: Text("Aktör Listesi"),
                    ),
                    DropdownMenuItem(
                      value: 'director',
                      child: Text("Yönetmen Listesi"),
                    ),
                  ],
                  onChanged: (val) => setState(() => tempType = val!),
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
                  if (listNameController.text.isNotEmpty) {
                    await MovieManager.instance.createCustomList(
                      listNameController.text.trim(),
                      tempType,
                    );
                    if (context.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  "Oluştur",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // --- PROFİL BAŞLIĞI (WIDGET OLARAK AYRILDI) ---
            ProfileHeader(onEditAvatar: () => _showAvatarSelection(context)),

            const SizedBox(height: 30),

            // --- LİSTELER BÖLÜMÜ ---
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

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('movie', "Filmler"),
                  const SizedBox(width: 10),
                  _buildFilterChip('actor', "Aktörler"),
                  const SizedBox(width: 10),
                  _buildFilterChip('director', "Yönetmenler"),
                ],
              ),
            ),
            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: MovieManager.instance.getUserListsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final listType = data['type'] ?? 'movie';
                  return listType == _selectedListType;
                }).toList();

                if (docs.isEmpty) {
                  return Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      "${_getTypeName(_selectedListType)} türünde listeniz yok.",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final items =
                          data['items'] as List? ??
                          data['movies'] as List? ??
                          [];

                      String coverImage = '';
                      if (items.isNotEmpty) {
                        coverImage =
                            items.first['poster_path'] ??
                            items.first['profile_path'] ??
                            '';
                      }

                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserListDetailView(
                              listId: docs[index].id,
                              listName: data['name'],
                              items: items,
                              type: _selectedListType,
                            ),
                          ),
                        ),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
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
                                  shadows: [
                                    Shadow(blurRadius: 5, color: Colors.black),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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

            // --- MENÜLER (WIDGET OLARAK AYRILDI) ---
            ProfileMenuItem(
              icon: Icons.people,
              text: "Arkadaşlarım",
              onTap: () => context.push(AppRouters.friends),
            ),
            ProfileMenuItem(
              icon: Icons.notifications,
              text: "Bildirim Geçmişi",
              onTap: () => context.push(AppRouters.notifications),
            ),
            ProfileMenuItem(
              icon: Icons.rate_review,
              text: "Değerlendirmelerim",
              onTap: () => context.push(AppRouters.userReviews),
            ),
            ProfileMenuItem(
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

  Widget _buildFilterChip(String type, String label) {
    final bool isSelected = _selectedListType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.surfaceDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) => setState(() => _selectedListType = type),
    );
  }

  String _getTypeName(String type) {
    if (type == 'movie') return 'Film';
    if (type == 'actor') return 'Aktör';
    return 'Yönetmen';
  }
}
