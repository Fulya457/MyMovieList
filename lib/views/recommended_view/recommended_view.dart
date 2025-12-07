import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/app/theme.dart';

class RecommendedView extends StatelessWidget {
  const RecommendedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text("Recommended For You"),
        backgroundColor: Colors.transparent, // Dark modda transparan şık durur
      ),
      body: ListenableBuilder(
        listenable: MovieManager.instance,
        builder: (context, child) {
          final allMovies = MovieManager.instance.allMovies;

          if (allMovies.isEmpty) {
            return const Center(
              child: Text(
                "Please go to Home first to load movies.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final recommendedList = List<Movie>.from(allMovies);
          if (recommendedList.length > 1) {
             recommendedList.shuffle();
          }
          final top5 = recommendedList.take(6).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: top5.length,
            itemBuilder: (context, index) {
              final movie = top5[index];
              return GestureDetector(
                onTap: () {
                   Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MovieDetailView(movie: movie)),
                    );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark, // Koyu Kart
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            movie.poster,
                            fit: BoxFit.cover,
                            errorBuilder: (c,o,s) => const Icon(Icons.error, color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "⭐ ${movie.rating}",
                              style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
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