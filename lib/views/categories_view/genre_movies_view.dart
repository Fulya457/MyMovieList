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
    // Sayfa açıldığında bu türdeki filmleri çekmeye başla
    GenreService.instance.fetchNextPageGenreMovies(widget.genre, initial: true);

    // Sonsuz kaydırma (Infinite Scroll)
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

  // --- LİSTEYE EKLEME PENCERESİ (HomeView'dan Alındı) ---
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
              const SizedBox(height: 10),
              const Divider(color: Colors.grey),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.playlist_add,
                              size: 50,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Henüz listeniz yok.",
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push(AppRouters.profile);
                              },
                              child: const Text(
                                "Liste oluşturmak için tıklayın",
                                style: TextStyle(color: AppTheme.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final listData =
                            docs[index].data() as Map<String, dynamic>;
                        final listId = docs[index].id;
                        final movies = listData['movies'] as List? ?? [];
                        final bool alreadyAdded = movies.any(
                          (m) => m['id'] == movie.id,
                        );

                        return ListTile(
                          leading: const Icon(Icons.list, color: Colors.white),
                          title: Text(
                            listData['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${movies.length} film",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check, color: Colors.green)
                              : const Icon(
                                  Icons.add,
                                  color: AppTheme.primaryBlue,
                                ),
                          onTap: () async {
                            if (!alreadyAdded) {
                              await MovieManager.instance.addMovieToCustomList(
                                listId,
                                movie,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${movie.title} listeye eklendi!",
                                    ),
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
        elevation: 0,
      ),
      // --- KRİTİK NOKTA: Hem Manager'ı hem Servisi Dinliyoruz ---
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

          if (movies.isEmpty) {
            return const Center(
              child: Text(
                "Bu türde film bulunamadı.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: movies.length + (state.hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
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
                  onTap: () => context.push('/movie-detail', extra: movie),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        // Film Posteri
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: movie.poster,
                            width: 70,
                            height: 105,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                              width: 70,
                              height: 105,
                              color: AppTheme.backgroundBlack,
                            ),
                            errorWidget: (c, u, e) => Container(
                              width: 70,
                              height: 105,
                              color: Colors.grey,
                              child: const Icon(Icons.movie),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Film Bilgileri
                        Expanded(
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
                                maxLines: 2,
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
                              const SizedBox(height: 5),
                              Text(
                                movie.genres.join(', '),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // BUTONLAR (Favori & Liste)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Listeye Ekle Butonu
                            IconButton(
                              icon: const Icon(
                                Icons.playlist_add,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  _showAddToListSheet(context, movie),
                            ),
                            // Favori Butonu
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                MovieManager.instance.toggleFavorite(movie);
                              },
                            ),
                          ],
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
}
