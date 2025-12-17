import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    MovieManager.instance.ensureUserExistsInFirestore();
    MovieManager.instance.fetchNextPageMovies(initial: true);
    MovieManager.instance.loadFavoritesFromFirebase();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        MovieManager.instance.fetchNextPageMovies();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getMemberName() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.contains('@')) {
      return email.substring(0, email.indexOf('@')).toUpperCase();
    }
    return 'USER';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      MovieManager.instance.searchMovies(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: AnimatedBuilder(
        animation: MovieManager.instance,
        builder: (context, child) {
          final manager = MovieManager.instance;
          final isSearching = _searchController.text.isNotEmpty;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. APP BAR (GÜNCELLENDİ: AVATAR EKLENDİ)
              SliverAppBar(
                backgroundColor: AppTheme.backgroundBlack.withOpacity(0.7),
                floating: true,
                pinned: true,
                elevation: 0,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                            // --- AVATAR BURAYA EKLENDİ ---
                            StreamBuilder<int>(
                              stream: MovieManager.instance
                                  .getCurrentUserIconIndex(),
                              builder: (context, snapshot) {
                                final index = snapshot.data ?? 0;
                                final iconUrl =
                                    MovieManager.instance.profileIcons[index];
                                return CircleAvatar(
                                  radius: 12, // Küçük boyut
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: NetworkImage(iconUrl),
                                );
                              },
                            ),
                            // -----------------------------
                            const SizedBox(width: 8),
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search Movies, Actors...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.primaryBlue,
                      ),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                                MovieManager.instance.searchMovies('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 20,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),

              if (isSearching) ...[
                if (manager.searchResults.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                        child: Text(
                          "Sonuç bulunamadı.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final movie = manager.searchResults[index];
                        return GestureDetector(
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: movie.poster,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              placeholder: (context, url) =>
                                  Container(color: AppTheme.surfaceDark),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                        );
                      }, childCount: manager.searchResults.length),
                    ),
                  ),
              ] else ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      children: [
                        Icon(Icons.whatshot, color: Colors.amber),
                        SizedBox(width: 10),
                        Text(
                          "Trending Movies",
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

                if (manager.trendingMovies.isNotEmpty)
                  SliverToBoxAdapter(
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 400.0,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        viewportFraction: 0.65,
                        autoPlayInterval: const Duration(seconds: 5),
                      ),
                      items: manager.trendingMovies.map((movie) {
                        return GestureDetector(
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: movie.poster,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: AppTheme.surfaceDark),
                                  errorWidget: (context, url, error) =>
                                      Container(color: Colors.grey),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.9),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 10,
                                  right: 10,
                                  child: Text(
                                    movie.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          color: AppTheme.primaryBlue,
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

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final movie = manager.allMovies[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: movie.poster,
                                    width: 70,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 150,
                                    placeholder: (context, url) => Container(
                                      width: 70,
                                      height: 100,
                                      color: AppTheme.surfaceDark,
                                    ),
                                    errorWidget: (c, u, e) => Container(
                                      width: 70,
                                      height: 100,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 14,
                                          ),
                                          Text(
                                            " ${movie.rating.toStringAsFixed(1)}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        movie.genres.isNotEmpty
                                            ? movie.genres.join(', ')
                                            : '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    manager.isFavorite(movie)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: manager.isFavorite(movie)
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () =>
                                      manager.toggleFavorite(movie),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: manager.allMovies.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                ),

                if (manager.isFetching)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ],
          );
        },
      ),
    );
  }
}
