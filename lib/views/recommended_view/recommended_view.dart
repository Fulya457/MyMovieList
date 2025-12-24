import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class RecommendedView extends StatefulWidget {
  const RecommendedView({super.key});

  @override
  State<RecommendedView> createState() => _RecommendedViewState();
}

class _RecommendedViewState extends State<RecommendedView> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında Firestore'dan Top Rated listesini çek
    MovieManager.instance.fetchAppTopRatedMovies();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        // ARTIK TMDB DEĞİL, UYGULAMA İÇİ PUANLARI ALIYORUZ
        final appTopRated = MovieManager.instance.appTopRatedMovies;
        final recommendedByGenre = MovieManager.instance
            .recommendByFavoriteGenres();

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            title: Text(
              'FOR YOU',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.backgroundBlack,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- 1. KISIM: KULLANICI PUANLI FİLMLER ---
              _buildSectionTitle(
                context,
                'Users\' Choice (App Rated > 6)',
                Icons.stars,
              ),
              const SizedBox(height: 10),
              // Eğer liste boşsa kullanıcıya bilgi ver
              _buildMovieList(
                context,
                appTopRated,
                'No ratings yet. Rate some movies to see them here!',
              ),

              const SizedBox(height: 30),

              // --- 2. KISIM: FAVORİ TÜR ÖNERİLERİ ---
              _buildSectionTitle(
                context,
                'Based on Your Favorites',
                Icons.category,
              ),
              const SizedBox(height: 10),
              _buildMovieList(
                context,
                recommendedByGenre,
                'Add favorites to get genre recommendations.',
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieList(
    BuildContext context,
    List<Movie> movies,
    String emptyMessage,
  ) {
    if (movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: movies.map((movie) {
        final isFav = MovieManager.instance.isFavorite(movie);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            color: AppTheme.surfaceDark,
            child: ListTile(
              onTap: () => context.push('/movie-detail', extra: movie),
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
                style: TextStyle(color: AppTheme.primaryBlue),
              ),
              subtitle: Row(
                children: [
                  Text(
                    '${movie.genres.isNotEmpty ? movie.genres.first : 'Movie'}',
                    style: TextStyle(
                      color: AppTheme.primaryBlue.withOpacity(0.8),
                    ),
                  ),
                  if (movie.appRating != null && movie.appRating! > 0)
                    Text(
                      ' • ⭐ ${movie.appRating!.toStringAsFixed(1)} (App)',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppTheme.primaryBlue : Colors.grey,
                ),
                onPressed: () => MovieManager.instance.toggleFavorite(movie),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
