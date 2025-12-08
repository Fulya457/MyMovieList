import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/app/theme.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack, // Simsiyah Arka Plan
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: Colors.transparent, // Transparan
      ),
      body: ListenableBuilder(
        listenable: MovieManager.instance,
        builder: (context, child) {
          final favorites = MovieManager.instance.favoriteMovies;

          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No favorites yet.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final movie = favorites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppTheme.surfaceDark, // Koyu Gri Kartlar
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    // Tıklayınca Detay Sayfasına Git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailView(movie: movie),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: Hero(
                      tag: 'poster_${movie.id}', // Hero Animasyonu
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          movie.poster,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            width: 50,
                            height: 75,
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, color: Colors.white),
                          ),
                        ),
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
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        // Favoriden Çıkar
                        MovieManager.instance.toggleFavorite(movie);
                      },
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