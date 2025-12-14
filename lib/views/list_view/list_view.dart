import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';

class MyListView extends StatelessWidget {
  const MyListView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Tüm filmleri çek
    final allMovies = MovieManager.instance.allMovies;

    // 2. Filmlerden benzersiz türleri (Genres) ayıkla
    // Örn: ["Drama", "Action", "Sci-Fi", "Drama"] -> ["Drama", "Action", "Sci-Fi"]
    final Set<String> uniqueGenres = {};
    for (var movie in allMovies) {
      uniqueGenres.addAll(movie.genres);
    }
    final List<String> genresList = uniqueGenres.toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text("Movie Genres"),
        backgroundColor: Colors.transparent,
      ),
      // EĞER FİLM YOKSA UYARI VER
      body: allMovies.isEmpty
          ? const Center(
              child: Text(
                "No movies loaded.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Yan yana 2 tane
                childAspectRatio:
                    1.1, // Kutuların kareye yakın (biraz yatay) olması için
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: genresList.length,
              itemBuilder: (context, index) {
                final genre = genresList[index];

                // Bu türdeki ilk filmi bul ve posterini kapak yap
                final coverMovie = allMovies.firstWhere(
                  (m) => m.genres.contains(genre),
                  orElse: () => allMovies.first,
                );

                return _CategoryCard(
                  genre: genre,
                  imageUrl: coverMovie.poster,
                  onTap: () {
                    // O türe ait filmlerin olduğu sayfaya git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenreMoviesView(genre: genre),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// --- TASARIM: KATEGORİ KARTI (RESİMLİ KUTU) ---
class _CategoryCard extends StatelessWidget {
  final String genre;
  final String imageUrl;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.genre,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Arka Plan Resmi
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(color: Colors.grey[800]),
              ),

              // 2. Karartma Efekti (Yazı okunsun diye)
              Container(color: Colors.black.withOpacity(0.6)),

              // 3. Kategori İsmi (Ortada)
              Center(
                child: Text(
                  genre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // 4. Mavi Dekoratif Çizgi (Alt kısım)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- İÇ SAYFA: SEÇİLEN TÜRDEKİ FİLMLER ---
class GenreMoviesView extends StatelessWidget {
  final String genre;

  const GenreMoviesView({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    // Sadece bu türe ait filmleri filtrele
    final movies = MovieManager.instance.allMovies
        .where((m) => m.genres.contains(genre))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text("$genre Movies"), // Örn: Drama Movies
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final isFav = MovieManager.instance.isFavorite(movie);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // FİLME TIKLAYINCA DETAY SAYFASINA GİT (FRAGMAN VS.)
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
                  tag: 'genre_${movie.id}', // Benzersiz Hero tag'i
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie.poster,
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
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
                  '⭐ ${movie.rating}',
                  style: TextStyle(
                    color: AppTheme.primaryBlue.withOpacity(0.8),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
