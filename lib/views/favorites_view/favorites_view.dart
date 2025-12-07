import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorilerim")),
      body: ListenableBuilder(
        listenable: MovieManager.instance,
        builder: (context, child) {
          final favorites = MovieManager.instance.favoriteMovies;

          if (favorites.isEmpty) {
            return const Center(child: Text("Henüz favori eklemediniz."));
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final movie = favorites[index];
              return Card(
                color: const Color(0xFF424242),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  // DÜZELTME BURADA YAPILDI: movie.thumbnail -> movie.poster
                  leading: Image.network(
                    movie.poster, 
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => const Icon(Icons.movie, color: Colors.white),
                  ),
                  title: Text(movie.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(movie.genres.isNotEmpty ? movie.genres.first : "", style: TextStyle(color: Colors.grey[400])),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      MovieManager.instance.toggleFavorite(movie);
                    },
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