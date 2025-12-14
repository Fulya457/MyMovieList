import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/data/review_service.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/app/theme.dart';

class RecommendedView extends StatefulWidget {
  const RecommendedView({super.key});

  @override
  State<RecommendedView> createState() => _RecommendedViewState();
}

class _RecommendedViewState extends State<RecommendedView> {
  final ReviewService _reviewService = ReviewService();
  List<Movie> userTopRatedMovies = [];
  List<Movie> genreRecommendedMovies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateRecommendations();
  }

  Future<void> _calculateRecommendations() async {
    final allMovies = MovieManager.instance.allMovies;
    if (allMovies.isEmpty) {
      MovieManager.instance.initializeMovies(); // Garanti olsun
    }

    // 1. KULLANICI PUANLARINA GÖRE SIRALAMA (YELLOW STAR)
    // Her film için Firebase'e gidip ortalama puanını öğreniyoruz.
    // (Büyük projelerde bu sunucuda yapılır ama 15 film için burada sorun olmaz)
    Map<int, double> movieUserRatings = {};

    for (var movie in allMovies) {
      double avg = await _reviewService.getMovieUserRating(movie.id);
      movieUserRatings[movie.id] = avg;
    }

    // Filmleri bu puanlara göre sırala
    userTopRatedMovies = List.from(allMovies);
    userTopRatedMovies.sort((a, b) {
      double ratingA = movieUserRatings[a.id] ?? 0;
      double ratingB = movieUserRatings[b.id] ?? 0;
      return ratingB.compareTo(ratingA); // Büyükten küçüğe
    });
    // Sadece puanı 0 olmayanları al ve ilk 5'i göster
    userTopRatedMovies = userTopRatedMovies
        .where((m) => (movieUserRatings[m.id] ?? 0) > 0)
        .take(5)
        .toList();

    // 2. FAVORİ TÜRLERİNE GÖRE ÖNERİ (AYNI MANTIK)
    final favorites = MovieManager.instance.favoriteMovies;
    if (favorites.isNotEmpty) {
      Set<String> userLikedGenres = {};
      for (var movie in favorites) {
        userLikedGenres.addAll(movie.genres);
      }
      genreRecommendedMovies = allMovies.where((movie) {
        if (favorites.contains(movie)) return false;
        return movie.genres.any((genre) => userLikedGenres.contains(genre));
      }).toList();
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          "For You",
          style: TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading:
            false, // Geri butonu olmasın (Alt menüden gelirse)
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BÖLÜM 1: TOP RATED BY USERS (SARI YILDIZ) ---
                  if (userTopRatedMovies.isNotEmpty) ...[
                    const Row(
                      children: [
                        Text(
                          "USER FAVORITES",
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.amber, size: 24),
                      ],
                    ),
                    const Text(
                      "Based on community ratings",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 15),

                    CarouselSlider(
                      options: CarouselOptions(
                        height: 350.0,
                        aspectRatio: 0.7,
                        viewportFraction: 0.55,
                        autoPlay: true,
                        enlargeCenterPage: true,
                      ),
                      items: userTopRatedMovies.map((movie) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailView(movie: movie),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  movie.poster,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    color: Colors.black87,
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ] else ...[
                    const Text(
                      "Rate movies to see User Favorites here!",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // --- BÖLÜM 2: TÜR ÖNERİLERİ ---
                  if (genreRecommendedMovies.isNotEmpty) ...[
                    const Row(
                      children: [
                        Text(
                          "BECAUSE YOU LIKED...",
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.recommend,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: genreRecommendedMovies.length,
                      itemBuilder: (context, index) {
                        final movie = genreRecommendedMovies[index];
                        return Card(
                          color: AppTheme.surfaceDark,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MovieDetailView(movie: movie),
                              ),
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                movie.poster,
                                width: 40,
                                height: 60,
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
                              "Genre Match: ${movie.genres.first}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const Text(
                      "Add movies to your favorites to get recommendations!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
