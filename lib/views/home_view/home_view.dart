import 'dart:ui'; // Blur efekti için
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // CustomScrollView kullandığımız için manuel controller'a gerek yok, Flutter kendi optimizasyonunu yapar.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    MovieManager.instance.ensureUserExistsInFirestore();
    MovieManager.instance.fetchNextPageMovies(initial: true);
    MovieManager.instance.loadFavoritesFromFirebase();

    // Sonsuz kaydırma için
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        MovieManager.instance.fetchNextPageMovies();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Sadece ismi al (Mailin @ öncesi)
  String _getMemberName() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.contains('@')) {
      return email.substring(0, email.indexOf('@')).toUpperCase();
    }
    return 'USER';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      // SafeArea kullanmıyoruz, içeriğin App Bar arkasına akmasını istiyoruz
      body: AnimatedBuilder(
        animation: MovieManager.instance,
        builder: (context, child) {
          final manager = MovieManager.instance;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // --- 1. GLASSMORPHISM APP BAR ---
              SliverAppBar(
                backgroundColor: AppTheme.backgroundBlack.withOpacity(
                  0.7,
                ), // Yarı saydam
                floating: true,
                pinned: true,
                elevation: 0,
                centerTitle: false,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10,
                      sigmaY: 10,
                    ), // Buzlu cam efekti
                    child: Container(color: Colors.transparent),
                  ),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.movie_filter_rounded,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "MyMovieList",
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () => context.push(AppRouters.profile),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getMemberName(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- 2. TRENDING HEADER ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.whatshot,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Trending Movies",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 3. TRENDING CAROUSEL ---
              if (manager.trendingMovies.isNotEmpty)
                SliverToBoxAdapter(
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 420.0,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 6),
                      autoPlayAnimationDuration: const Duration(
                        milliseconds: 800,
                      ),
                      enlargeCenterPage: true,
                      viewportFraction: 0.60,
                      aspectRatio: 16 / 9,
                    ),
                    items: manager.trendingMovies.map((movie) {
                      return GestureDetector(
                        onTap: () =>
                            context.push('/movie-detail', extra: movie),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 10,
                          ), // Gölge için pay
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  movie.poster,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) =>
                                      Container(color: AppTheme.surfaceDark),
                                ),
                                // Gradient Overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.0),
                                        Colors.black.withOpacity(0.9),
                                      ],
                                      stops: const [0.0, 0.6, 1.0],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 15,
                                  right: 15,
                                  child: Column(
                                    children: [
                                      Text(
                                        movie.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          Text(
                                            " ${movie.rating.toStringAsFixed(1)}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // --- 4. POPULAR HEADER ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        height: 25,
                        width: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Popular Movies",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 5. POPULAR LIST (PERFORMANS İÇİN SLIVER LIST) ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final movie = manager.allMovies[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
                          child: Row(
                            children: [
                              // Poster
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: Image.network(
                                  movie.poster,
                                  height: 120,
                                  width: 85,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Container(
                                    width: 85,
                                    height: 120,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Bilgi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 14,
                                              ),
                                              Text(
                                                " ${movie.rating.toStringAsFixed(1)}",
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          movie.genres.isNotEmpty
                                              ? movie.genres[0]
                                              : "Movie",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Fav Butonu
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: Icon(
                                    manager.isFavorite(movie)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: manager.isFavorite(movie)
                                        ? AppTheme.accentPink
                                        : Colors.grey,
                                  ),
                                  onPressed: () =>
                                      manager.toggleFavorite(movie),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: manager.allMovies.length),
                ),
              ),

              // Yükleniyor...
              if (manager.isFetching)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
    );
  }
}
