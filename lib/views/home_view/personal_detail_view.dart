// Dosya: lib/views/home_view/personal_detail_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

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

  // --- LİSTE OLUŞTURMA PENCERESİ ---
  void _showCreateListDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "New Contact List",
          style: TextStyle(color: AppTheme.textColor), // Mavi/Beyaz Yazı
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: AppTheme.textColor), // Mavi/Beyaz Yazı
          decoration: InputDecoration(
            hintText: "List Name...",
            hintStyle: TextStyle(
              color: AppTheme.textColor.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.black12, // Hafif koyuluk
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
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // LİSTEYE EKLEME PENCERESİ
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
                "Add to List: ${widget.person.name}",
                style: TextStyle(
                  color: AppTheme.textColor, // Mavi/Beyaz Yazı
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
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
                            Text(
                              "You don't have a contact list.",
                              style: TextStyle(
                                color: AppTheme.textColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                              onPressed: () {
                                _showCreateListDialog();
                              },
                              child: const Text(
                                "Create New Contact List",
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
                          leading: Icon(
                            Icons.person_add,
                            color: AppTheme.iconColor,
                          ),
                          title: Text(
                            data['name'],
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                          subtitle: Text(
                            "${items.length} kişi",
                            style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.6),
                            ),
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
                                  const SnackBar(content: Text("Added!")),
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
    // AnimatedBuilder eklenerek tema değişimi dinleniyor
    return AnimatedBuilder(
      animation: MovieManager.instance,
      builder: (context, child) {
        final manager = MovieManager.instance;
        final isFav = manager.isPersonFavorite(widget.person);

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack, // Dinamik Arka Plan
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
                    onPressed: () =>
                        manager.togglePersonFavorite(widget.person),
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
                        style: TextStyle(
                          color: AppTheme.textColor, // Mavi/Beyaz Yazı
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Known for: ${widget.person.knownFor}",
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Biyografi
                      Text(
                        "Biography",
                        style: TextStyle(
                          color: AppTheme.textColor, // Mavi/Beyaz Yazı
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.person.biography.isNotEmpty
                            ? widget.person.biography
                            : "No biography available.",
                        style: TextStyle(
                          color: AppTheme.textColor.withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 30),

                      // --- FİLM ARAMA ALANI ---
                      Text(
                        "Filmography",
                        style: TextStyle(
                          color: AppTheme.textColor, // Mavi/Beyaz Yazı
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: AppTheme.textColor),
                        onChanged: _searchMovies,
                        decoration: InputDecoration(
                          hintText: "${widget.person.name} filmlerinde ara...",
                          hintStyle: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                          ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        "Movie not found.",
                        style: TextStyle(
                          color: AppTheme.textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
      },
    );
  }
}
