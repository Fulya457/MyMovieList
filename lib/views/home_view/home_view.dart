import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/app/theme.dart';
import 'dart:async';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String searchQuery = "";
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final manager = MovieManager.instance;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !manager.isFetching &&
        manager.hasMorePages) {
      manager.fetchNextPageMovies();
    }
  }

  Future<void> _loadData() async {
    try {
      await MovieManager.instance.fetchNextPageMovies(initial: true);
    } catch (e) {
      print('Movie loading error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRouters.login);
  }

  // APP BAR İÇERİĞİ TEKRAR ESKİ HALİNE DÖNDÜRÜLDÜ
  Widget _homeAppBarContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.movie_filter_rounded,
                color: AppTheme.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                "MY MOVIE LIST", // BÜYÜK HARFE DÖNDÜ
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2, // ESKİ STİL EKLENDİ
                ),
              ),
            ],
          ),
          Row(
            children: [
              // ÖNERİLER SAYFASINA GİTME BUTONU (ŞİMDİLİK AYNI YERİ GÖSTERİYOR AMA İÇERİĞİ ALT MENÜYE TAŞIDIK)
              IconButton(
                icon: const Icon(Icons.recommend, color: Colors.amber),
                onPressed: () {
                  // Alt menüdeki sekmeye atlamak için context.go kullanıyoruz
                  context.go(AppRouters.recommends);
                },
                tooltip: "For You",
              ),
              IconButton(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        final allMovies = MovieManager.instance.allMovies;
        final trendingMovies = MovieManager.instance.trendingMovies;
        final isFetching = MovieManager.instance.isFetching;
        final hasMore = MovieManager.instance.hasMorePages;

        final filteredMovies = allMovies
            .where(
              (movie) =>
                  movie.title.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      // --- BAŞLIK, ÖNERİ VE ÇIKIŞ BUTONLARI ---
                      _homeAppBarContent(context),

                      // --- ARAMA KUTUSU ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: AppTheme.primaryBlue,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppTheme.primaryBlue,
                            ),
                            hintText: 'Search movies...',
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- ÖZEL LİSTELER ---
                      if (!isLoading && searchQuery.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                "TRENDING NOW",
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.whatshot,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        // --- CAROUSEL SLIDER ---
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 400.0,
                            aspectRatio: 0.7,
                            viewportFraction: 0.6,
                            autoPlay: true,
                            enlargeCenterPage: true,
                          ),
                          items: trendingMovies
                              .map(
                                (movie) => GestureDetector(
                                  onTap: () => context.push(
                                    '/movie-detail',
                                    extra: movie,
                                  ),
                                  child: Hero(
                                    tag: 'trend_${movie.id}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        movie.poster,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        errorBuilder: (c, o, s) =>
                                            Container(color: Colors.grey[800]),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 30),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "ALL MOVIES",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // --- YÜKLENİYOR İNDİKATÖRÜ ---
                      if (isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      else if (filteredMovies.isEmpty)
                        const Center(
                          child: Text(
                            'No movies found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        // --- TÜM FİLMLER LİSTESİ (Sonsuz Kaydırma ile) ---
                        ...List.generate(filteredMovies.length, (index) {
                          final movie = filteredMovies[index];
                          final isFav = MovieManager.instance.isFavorite(movie);

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
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFav
                                        ? AppTheme.primaryBlue
                                        : Colors.grey,
                                  ),
                                  onPressed: () => MovieManager.instance
                                      .toggleFavorite(movie),
                                ),
                              ),
                            ),
                          );
                        }),

                      // --- KAYDIRMA İNDİKATÖRÜ ---
                      if (isFetching && hasMore && searchQuery.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),

                      // --- LİSTE SONU MESAJI ---
                      if (!hasMore &&
                          !isLoading &&
                          filteredMovies.isNotEmpty &&
                          searchQuery.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'You have reached the end of the movie list.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
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
  }
}
