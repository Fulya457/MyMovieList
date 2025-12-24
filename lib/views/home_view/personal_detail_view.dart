// Dosya: lib/views/home_view/personal_detail_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';

// Widget
import 'package:mymovielist/views/home_view/widgets/movie_card.dart';

class PersonDetailView extends StatefulWidget {
  final Person person;
  const PersonDetailView({super.key, required this.person});

  @override
  State<PersonDetailView> createState() => _PersonDetailViewState();
}

class _PersonDetailViewState extends State<PersonDetailView> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _filteredMovies = [];

  @override
  void initState() {
    super.initState();
    // İlk başta tüm filmleri göster
    _filteredMovies = widget.person.filmography;

    // Detayları çek (Biyografi ve Tam Filmografi)
    MovieManager.instance.fetchPersonDetails(widget.person).then((_) {
      if (mounted) {
        setState(() {
          // Veri güncellenince listeyi de güncelle
          _filteredMovies = widget.person.filmography;
        });
      }
    });
  }

  // FİLM ARAMA FONKSİYONU
  void _searchMovies(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMovies = widget.person.filmography;
      });
    } else {
      setState(() {
        _filteredMovies = widget.person.filmography.where((movie) {
          return movie.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  // --- YENİ EKLENEN: LİSTE OLUŞTURMA PENCERESİ ---
  void _showCreateListDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          "Yeni Kişi Listesi",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Liste Adı...",
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
              if (nameController.text.trim().isNotEmpty) {
                // 'actor' türünde liste oluştur
                await MovieManager.instance.createCustomList(
                  nameController.text.trim(),
                  'actor',
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Liste oluşturuldu!")),
                  );
                }
              }
            },
            child: const Text("Oluştur", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // LİSTEYE EKLEME PENCERESİ (Sadece Kişi Listeleri)
  void _showAddToListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Text(
                "Listeye Ekle: ${widget.person.name}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;

                    final personLists = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['type'] == 'actor';
                    }).toList();

                    if (personLists.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Hiç kişi listeniz yok.",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            // YENİ EKLENEN BUTON
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                              onPressed: () {
                                // BottomSheet açık kalabilir, dialog üstüne açılır
                                // Liste oluşunca Stream sayesinde burası otomatik güncellenir
                                _showCreateListDialog();
                              },
                              child: const Text(
                                "Yeni Kişi Listesi Oluştur",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: personLists.length,
                      itemBuilder: (context, index) {
                        final data =
                            personLists[index].data() as Map<String, dynamic>;
                        final items = data['items'] as List? ?? [];
                        final bool exists = items.any(
                          (i) => i['id'] == widget.person.id,
                        );

                        return ListTile(
                          leading: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                          ),
                          title: Text(
                            data['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${items.length} kişi",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: exists
                              ? const Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.add, color: AppTheme.primaryBlue),
                          onTap: () async {
                            if (!exists) {
                              await MovieManager.instance.addItemToCustomList(
                                personLists[index].id,
                                widget.person.toMap(),
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Eklendi!")),
                                );
                              }
                            }
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

  @override
  Widget build(BuildContext context) {
    final manager = MovieManager.instance;
    final isFav = manager.isPersonFavorite(widget.person);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          // 1. ÜST PROFİL RESMİ
          SliverAppBar(
            backgroundColor: AppTheme.backgroundBlack,
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.person.profilePath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.playlist_add, color: Colors.white),
                ),
                onPressed: _showAddToListSheet,
              ),
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.white,
                  ),
                ),
                onPressed: () => manager.togglePersonFavorite(widget.person),
              ),
            ],
          ),

          // 2. İSİM VE BİYOGRAFİ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.person.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Known for: ${widget.person.knownFor}",
                    style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // Biyografi
                  const Text(
                    "Biography",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.person.biography.isNotEmpty
                        ? widget.person.biography
                        : "No biography available.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 30),

                  // --- FİLM ARAMA ALANI ---
                  const Text(
                    "Filmography",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _searchMovies,
                    decoration: InputDecoration(
                      hintText: "${widget.person.name} filmlerinde ara...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.primaryBlue,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // 3. FİLM IZGARASI (GRID)
          if (_filteredMovies.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    "Film bulunamadı.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final movie = _filteredMovies[index];
                  // MovieCard kullanıyoruz (Grid modunda)
                  return MovieCard(movie: movie, isGrid: true);
                }, childCount: _filteredMovies.length),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
        ],
      ),
    );
  }
}
