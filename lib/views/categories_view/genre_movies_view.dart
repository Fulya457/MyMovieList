// Dosya: lib/views/home_view/genre_movies_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/data/genre_service.dart';

class GenreMoviesView extends StatefulWidget {
  final String genre;
  const GenreMoviesView({super.key, required this.genre});

  @override
  State<GenreMoviesView> createState() => _GenreMoviesViewState();
}

class _GenreMoviesViewState extends State<GenreMoviesView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GenreService.instance.fetchNextPageGenreMovies(widget.genre, initial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        GenreService.instance.fetchNextPageGenreMovies(widget.genre);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- LİSTE OLUŞTURMA PENCERESİ (HomeView'dan Kopyalandı) ---
  void _showCreateListDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "Create New List",
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                hintText: "List Name (e.g., To Watch Lists)",
                hintStyle: TextStyle(
                  color: AppTheme.textColor.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.black26,
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
              if (nameController.text.trim().isNotEmpty) {
                await MovieManager.instance.createCustomList(
                  nameController.text.trim(),
                  'movies',
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("List created successfully!")),
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

  // --- LİSTEYE EKLEME PENCERESİ ---
  void _showAddToListSheet(BuildContext context, Movie movie) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add to List: ${movie.title}",
                style: TextStyle(
                  color: AppTheme.textColor, // Dinamik
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Divider(color: AppTheme.textColor.withValues(alpha: 0.2)),

              // --- YENİ LİSTE OLUŞTUR BUTONU ---
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: AppTheme.primaryBlue),
                ),
                title: Text(
                  "Create New List",
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateListDialog(context);
                },
              ),
              const Divider(color: Colors.grey),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue,
                        ),
                      );
                    }
                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "You don't have a list yet.",
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final listData =
                            docs[index].data() as Map<String, dynamic>;
                        final listId = docs[index].id;

                        // Sadece film listelerini göster
                        if (listData['type'] != null &&
                            listData['type'] != 'movies' &&
                            listData['type'] != 'movie') {
                          return const SizedBox.shrink();
                        }

                        final movies = listData['items'] as List? ?? [];
                        final bool alreadyAdded = movies.any(
                          (m) => m['id'] == movie.id,
                        );

                        return ListTile(
                          leading: Icon(Icons.list, color: AppTheme.iconColor),
                          title: Text(
                            listData['name'] ?? 'İsimsiz',
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                          subtitle: Text(
                            "${movies.length} film",
                            style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.add, color: AppTheme.primaryBlue),
                          onTap: () async {
                            if (!alreadyAdded) {
                              await MovieManager.instance.addMovieToCustomList(
                                listId,
                                movie,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Added to list!"),
                                  ),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          MovieManager.instance,
          GenreService.instance,
        ]),
        builder: (context, child) {
          final state = GenreService.instance.getGenreState(widget.genre);
          final movies = state.movies;
          final isDark = MovieManager.instance.isDarkMode;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // --- 1. PROFIL TARZI GRADIENT HEADER ---
              SliverAppBar(
                expandedHeight:
                    120, // Biraz yükseklik verip gradient'i gösteriyoruz
                pinned: true,
                backgroundColor: AppTheme.backgroundBlack,
                iconTheme: IconThemeData(color: AppTheme.textColor),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          // Üstten gelen renk (Tema rengi)
                          AppTheme.primaryBlue.withValues(
                            alpha: isDark ? 0.3 : 0.2,
                          ),
                          AppTheme.backgroundBlack,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.genre.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppTheme.textColor, // Dinamik Renk
                          shadows: [
                            Shadow(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- 2. İÇERİK ---
              if (state.isFetching && movies.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )
              else if (movies.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No movie found in this genre.",
                      style: TextStyle(
                        color: AppTheme.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == movies.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final movie = movies[index];
                      final isFav = MovieManager.instance.isFavorite(movie);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                // Film Posteri
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Hero(
                                    tag: 'movie_${movie.id}',
                                    child: CachedNetworkImage(
                                      imageUrl: movie.poster,
                                      width: 80,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(
                                        width: 80,
                                        height: 120,
                                        color: AppTheme.backgroundBlack,
                                      ),
                                      errorWidget: (c, u, e) => Container(
                                        width: 80,
                                        height: 120,
                                        color: Colors.grey,
                                        child: const Icon(Icons.movie),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),

                                // Film Bilgileri
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie.title,
                                        style: TextStyle(
                                          color: AppTheme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          Text(
                                            " ${movie.rating.toStringAsFixed(1)}",
                                            style: TextStyle(
                                              color: AppTheme.textColor
                                                  .withValues(alpha: 0.7),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        movie.genres.join(', '),
                                        style: TextStyle(
                                          color: AppTheme.textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Butonlar
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFav
                                            ? Colors.red
                                            : AppTheme.iconColor.withValues(
                                                alpha: 0.5,
                                              ),
                                      ),
                                      onPressed: () {
                                        MovieManager.instance.toggleFavorite(
                                          movie,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.playlist_add,
                                        color: AppTheme.iconColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _showAddToListSheet(context, movie),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: movies.length + (state.hasMorePages ? 1 : 0)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
