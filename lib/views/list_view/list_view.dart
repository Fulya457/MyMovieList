import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';

class MyListView extends StatelessWidget {
  const MyListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Film Türleri")),
      body: ListenableBuilder(
        listenable: MovieManager.instance,
        builder: (context, child) {
          final allMovies = MovieManager.instance.allMovies;

          if (allMovies.isEmpty) return const Center(child: Text("Veri yükleniyor..."));

          // --- TÜRLERE GÖRE GRUPLA ---
          // Bir film hem "Drama" hem "Suç" olabilir, ikisine de ekleyeceğiz.
          final Map<String, List<Movie>> categories = {};
          
          for (var movie in allMovies) {
            for (var genre in movie.genres) {
              if (!categories.containsKey(genre)) {
                categories[genre] = [];
              }
              categories[genre]!.add(movie);
            }
          }

          return ListView.builder(
            itemCount: categories.keys.length,
            itemBuilder: (context, index) {
              String genreName = categories.keys.elementAt(index);
              List<Movie> moviesInGenre = categories[genreName]!;

              return ExpansionTile(
                title: Text("$genreName (${moviesInGenre.length})"),
                children: moviesInGenre.map((movie) => ListTile(
                  title: Text(movie.title),
                  leading: const Icon(Icons.movie_creation_outlined),
                )).toList(),
              );
            },
          );
        },
      ),
    );
  }
}