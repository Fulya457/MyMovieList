import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Set<String> _myFriendIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Arkadaş listesini dinle (Ekle/Çıkar durumunu anlık güncellemek için)
    MovieManager.instance.getFriendsStream().listen((snapshot) {
      if (mounted) {
        setState(() {
          _myFriendIds = snapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    });
  }

  void _searchUsers() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchResults = [];
    });

    final results = await MovieManager.instance.searchUsersByEmail(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  // --- SİLME ONAY KUTUSU (YENİ) ---
  void _showDeleteConfirmation(String friendUid, String friendEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          "Arkadaşı Sil",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "$friendEmail kişisini arkadaşlıktan çıkarmak istiyor musun?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Dialogu kapat
              await MovieManager.instance.removeFriend(friendUid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Arkadaş silindi.")),
                );
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
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
        title: const Text(
          "Sosyal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Arkadaşlar"),
            Tab(text: "İstekler"),
            Tab(text: "Arkadaş Ekle"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyFriendsList(),
          _buildFriendRequests(),
          _buildAddFriendPage(),
        ],
      ),
    );
  }

  // 1. SEKME: ARKADAŞLARIM (GÜNCELLENDİ)
  Widget _buildMyFriendsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: MovieManager.instance.getFriendsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.white10),
                SizedBox(height: 10),
                Text(
                  "Henüz arkadaşın yok.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final friendUid = data['uid'];
            final friendEmail = data['email'];

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                  child: Text(
                    friendEmail[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  friendEmail,
                  style: const TextStyle(color: Colors.white),
                ),

                // İŞLEM BUTONLARI
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mesaj Butonu
                    IconButton(
                      icon: const Icon(
                        Icons.message_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      onPressed: () => context.push(
                        AppRouters.chat,
                        extra: {
                          'targetUid': friendUid,
                          'targetEmail': friendEmail,
                          'movie': null,
                        },
                      ),
                    ),
                    // Silme Butonu (YENİ)
                    IconButton(
                      icon: const Icon(
                        Icons.person_remove,
                        color: Colors.redAccent,
                      ),
                      onPressed: () =>
                          _showDeleteConfirmation(friendUid, friendEmail),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. SEKME: İSTEKLER
  Widget _buildFriendRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: MovieManager.instance.getFriendRequestsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(
            child: Text(
              "Bekleyen istek yok.",
              style: TextStyle(color: Colors.grey),
            ),
          );

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              color: AppTheme.surfaceDark,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.person_add, color: Colors.black),
                ),
                title: Text(
                  data['email'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Arkadaşlık isteği",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => MovieManager.instance.acceptFriendRequest(
                    data['from_uid'],
                    data['email'],
                  ),
                  child: const Text(
                    "Kabul Et",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. SEKME: ARKADAŞ EKLE
  Widget _buildAddFriendPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Email ile ara...",
              filled: true,
              fillColor: AppTheme.surfaceDark,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.arrow_forward,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: _searchUsers,
              ),
            ),
            onSubmitted: (_) => _searchUsers(),
          ),
          const SizedBox(height: 20),

          if (_isSearching)
            const CircularProgressIndicator(color: AppTheme.primaryBlue)
          else if (_hasSearched && _searchResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Kullanıcı bulunamadı.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final uid = user['uid'];
                  final isAlreadyFriend = _myFriendIds.contains(uid);

                  return Card(
                    color: AppTheme.surfaceDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        user['email'],
                        style: const TextStyle(color: Colors.white),
                      ),

                      trailing: isAlreadyFriend
                          ? const Chip(
                              label: Text(
                                "Zaten Arkadaşsınız",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.grey,
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () async {
                                await MovieManager.instance.sendFriendRequest(
                                  uid,
                                );
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("İstek gönderildi!"),
                                    ),
                                  );
                              },
                              child: const Text(
                                "Ekle",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
