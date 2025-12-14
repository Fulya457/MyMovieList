import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/data/genre_service.dart'; // YENİ SERVİS
import 'package:mymovielist/views/home_view/movie_detail_view.dart';

class GenreMoviesView extends StatefulWidget {
  final String genre;
  const GenreMoviesView({super.key, required this.genre});

  @override
  State<GenreMoviesView> createState() => _GenreMoviesViewState();
}

class _GenreMoviesViewState extends State<GenreMoviesView> {
  final GenreService _genreService = GenreService.instance;
  late final ScrollController _scrollController;

  // Kategorinin anlık durumunu al
  GenreState get _state => _genreService.getGenreState(widget.genre);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // İlk 20 filmi yükle
    _genreService.fetchNextPageGenreMovies(widget.genre, initial: true);
  }

  void _scrollListener() {
    // Listenin sonuna yaklaştıysa (son 300 piksel)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _genreService.fetchNextPageGenreMovies(widget.genre);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // GenreService'daki değişiklikleri dinle
      listenable: _genreService,
      builder: (context, child) {
        final movies = _state.movies;
        final isFetching = _state.isFetching;
        final hasMore = _state.hasMorePages;
        final isInitialLoading = isFetching && movies.isEmpty;

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            title: Text(
              widget.genre,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
          ),
          body: isInitialLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                )
              : movies.isEmpty && !isFetching
              ? const Center(
                  child: Text(
                    'No movies found for this genre.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount:
                      movies.length + 1, // +1, yükleniyor göstergesi için
                  itemBuilder: (context, index) {
                    if (index == movies.length) {
                      // Listenin sonu: Yükleniyor göstergesi
                      if (isFetching && hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        );
                      } else if (!hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'You have reached the end of the list.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    // Normal Film Öğesi
                    final movie = movies[index];
                    final isFav = MovieManager.instance.isFavorite(movie);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.surfaceDark,
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailView(movie: movie),
                            ),
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              movie.poster,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          title: Text(
                            movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${movie.genres.first} • ⭐ ${movie.rating}',
                            style: TextStyle(
                              color: AppTheme.primaryBlue.withOpacity(0.8),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? AppTheme.primaryBlue : Colors.grey,
                            ),
                            onPressed: () =>
                                MovieManager.instance.toggleFavorite(movie),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
