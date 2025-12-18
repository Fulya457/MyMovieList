import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text('Favoriler', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.backgroundBlack,
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Filmler"),
              Tab(text: "Aktörler"),
              Tab(text: "Yönetmenler"),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: MovieManager.instance,
          builder: (context, child) {
            return TabBarView(
              children: [
                _buildMovieList(MovieManager.instance.favoriteMovies),
                _buildPersonList(MovieManager.instance.favoriteActors),
                _buildPersonList(MovieManager.instance.favoriteDirectors),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMovieList(List<Movie> movies) {
    if (movies.isEmpty)
      return const Center(
        child: Text("Favori film yok.", style: TextStyle(color: Colors.grey)),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return ListTile(
          leading: CachedNetworkImage(
            imageUrl: movie.poster,
            width: 50,
            fit: BoxFit.cover,
          ),
          title: Text(movie.title, style: const TextStyle(color: Colors.white)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => MovieManager.instance.toggleFavorite(movie),
          ),
          onTap: () => context.push('/movie-detail', extra: movie),
        );
      },
    );
  }

  Widget _buildPersonList(List<Person> people) {
    if (people.isEmpty)
      return const Center(
        child: Text("Listeniz boş.", style: TextStyle(color: Colors.grey)),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(person.profilePath),
          ),
          title: Text(person.name, style: const TextStyle(color: Colors.white)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => MovieManager.instance.togglePersonFavorite(person),
          ),
          onTap: () => context.push('/person-detail', extra: person),
        );
      },
    );
  }
}
