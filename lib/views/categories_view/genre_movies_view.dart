import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
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
    // Sayfa açılırken filmleri çek
    GenreService.instance.fetchNextPageGenreMovies(widget.genre, initial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        GenreService.instance.fetchNextPageGenreMovies(widget.genre);
      }
    });
  }

  // --- LİSTEYE EKLEME PENCERESİ (Home ile birebir aynı) ---
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
                "Listeye Ekle: ${movie.title}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(AppRouters.profile);
                          },
                          child: const Text(
                            "Henüz listen yok, oluşturmak için tıkla",
                            style: TextStyle(color: AppTheme.primaryBlue),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final listData =
                            docs[index].data() as Map<String, dynamic>;
                        final moviesInList = listData['movies'] as List? ?? [];
                        final bool alreadyAdded = moviesInList.any(
                          (m) => m['id'] == movie.id,
                        );
                        return ListTile(
                          leading: const Icon(Icons.list, color: Colors.white),
                          title: Text(
                            listData['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Icon(
                            alreadyAdded
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: alreadyAdded
                                ? Colors.green
                                : AppTheme.primaryBlue,
                          ),
                          onTap: () async {
                            if (!alreadyAdded) {
                              await MovieManager.instance.addMovieToCustomList(
                                docs[index].id,
                                movie,
                              );
                              if (mounted) Navigator.pop(ctx);
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
      appBar: AppBar(
        title: Text(
          widget.genre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // --- BURASI SİHİRLİ NOKTA: HomeView'daki AnimatedBuilder ---
      body: ListenableBuilder(
        listenable: Listenable.merge([
          MovieManager.instance,
          GenreService.instance,
        ]),
        builder: (context, child) {
          final state = GenreService.instance.getGenreState(widget.genre);
          final movies = state.movies;

          if (state.isFetching && movies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final isFav = MovieManager.instance.isFavorite(movie);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // 1. Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: movie.poster,
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // 2. Bilgiler
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            context.push('/movie-detail', extra: movie),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                Text(
                                  " ${movie.rating.toStringAsFixed(1)}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 3. BUTONLAR (KALP VE LİSTE)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // LİSTEYE EKLE (Playlist add)
                        IconButton(
                          icon: const Icon(
                            Icons.playlist_add,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => _showAddToListSheet(context, movie),
                        ),
                        // FAVORİ (KALP)
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey,
                            size: 28,
                          ),
                          onPressed: () =>
                              MovieManager.instance.toggleFavorite(movie),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
