// Lütfen bu dosyayı açın ve aşağıdaki Scaffold yapısını uygulayın:

import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart'; // MovieDetailView için

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        final favorites = MovieManager.instance.favoriteMovies;

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            // <-- AppView'dan kaldırılan başlık buraya eklendi
            title: const Text(
              'FAVORITES',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.backgroundBlack,
          ),
          body: favorites.isEmpty
              ? const Center(
                  child: Text(
                    "Your favorites list is empty.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final movie = favorites[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.surfaceDark,
                        child: ListTile(
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
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
                            icon: const Icon(
                              Icons.favorite,
                              color: AppTheme.primaryBlue,
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
