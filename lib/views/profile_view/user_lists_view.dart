import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class UserListsView extends StatelessWidget {
  const UserListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        title: const Text('Listelerim', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: MovieManager.instance.getUserListsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.playlist_add, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Henüz bir listeniz yok.",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Filmleri gruplamak için yeni bir liste oluşturun.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Yeni Liste Oluştur", style: TextStyle(color: Colors.white, fontSize: 16)),
                    onPressed: () {
                      _showCreateListDialog(context);
                    },
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final items = data['items'] as List? ?? [];
              
              // Liste içindeki ilk filmin posterini kapak yapalım
              String? coverImage;
              if (items.isNotEmpty) {
                 coverImage = items.first['poster_path'];
              }

              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomListDetailView(
                          listId: doc.id,
                          listName: data['name'] ?? 'Liste',
                          initialItems: items,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Kapak Resmi
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            image: coverImage != null 
                              ? DecorationImage(image: NetworkImage(coverImage), fit: BoxFit.cover)
                              : null,
                          ),
                          child: coverImage == null 
                             ? const Icon(Icons.movie, color: Colors.white24, size: 30) 
                             : null,
                        ),
                        const SizedBox(width: 16),
                        // Bilgiler
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'İsimsiz Liste',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${items.length} film",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Silme Butonu
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            _confirmDelete(context, doc.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Yeni Liste", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Liste Adı (örn: Favori Dramalar)", 
            filled: true, 
            fillColor: Colors.black26,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                MovieManager.instance.createCustomList(nameController.text.trim(), 'movies');
                Navigator.pop(ctx);
              }
            },
            child: const Text("Oluştur", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String listId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Listeyi Sil?", style: TextStyle(color: Colors.white)),
        content: const Text("Bu işlem geri alınamaz. Liste kalıcı olarak silinecek.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () {
              MovieManager.instance.deleteCustomList(listId);
              Navigator.pop(ctx);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- LİSTE DETAY SAYFASI (GÜNCELLENDİ) ---
// Artık StatefulWidget kullanarak silme işlemi sonrası anlık güncellemeyi sağlıyoruz.
class CustomListDetailView extends StatefulWidget {
  final String listId;
  final String listName;
  final List<dynamic> initialItems;

  const CustomListDetailView({
    super.key,
    required this.listId,
    required this.listName,
    required this.initialItems,
  });

  @override
  State<CustomListDetailView> createState() => _CustomListDetailViewState();
}

class _CustomListDetailViewState extends State<CustomListDetailView> {
  late List<dynamic> currentItems;

  @override
  void initState() {
    super.initState();
    currentItems = List.from(widget.initialItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        title: Text(widget.listName, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentItems.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 10),
                const Text("Bu liste boş.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: currentItems.length,
            itemBuilder: (context, index) {
              final movieMap = currentItems[index] as Map<String, dynamic>;
              final movie = Movie.fromMap(movieMap);

              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      movie.poster,
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (c,o,s) => Container(width: 50, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    movie.title, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    movie.releaseDate.isEmpty ? "Tarih Yok" : movie.releaseDate, 
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    tooltip: "Listeden Çıkar",
                    onPressed: () async {
                      // Firebase'den sil
                      await MovieManager.instance.removeMovieFromCustomList(widget.listId, movieMap);
                      
                      // Lokal listeyi güncelle
                      setState(() {
                        currentItems.removeAt(index);
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Film listeden kaldırıldı."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                  onTap: () {
                     context.push('/movie-detail', extra: movie);
                  },
                ),
              );
            },
          ),
    );
  }
}
