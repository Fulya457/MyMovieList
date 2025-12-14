// lib/views/recommended_view/recommended_view.dart dosyasının FULL HALİ

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class RecommendedView extends StatelessWidget {
  const RecommendedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        final topRated = MovieManager.instance.topRatedMovies;
        final recommendedByGenre = MovieManager.instance
            .recommendByFavoriteGenres();

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            title: const Text(
              'FOR YOU',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.backgroundBlack,
            iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- 1. KISIM: 7.5 ÜZERİ FİLMLER ---
              _buildSectionTitle(context, 'Top Rated (7.5+)', Icons.star_half),
              const SizedBox(height: 10),
              _buildMovieList(context, topRated, 'No movies rated 7.5+ found.'),

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

  // Yardımcı Başlık Widget'ı
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Yardımcı Film Listesi Widget'ı
  Widget _buildMovieList(
    BuildContext context,
    List<Movie> movies,
    String emptyMessage,
  ) {
    if (movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
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
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${movie.genres.first} • ⭐ ${movie.rating}',
                style: TextStyle(color: AppTheme.primaryBlue.withOpacity(0.8)),
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
