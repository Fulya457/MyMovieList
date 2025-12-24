// Dosya: lib/views/home_view/home_view.dart

import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/models/movie_model.dart';

// Widget Imports
import 'package:mymovielist/views/home_view/widgets/movie_card.dart';
import 'package:mymovielist/views/home_view/widgets/person_card.dart';
import 'package:mymovielist/views/home_view/widgets/search_filter_modal.dart';

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
    MovieManager.instance.listenToFriendsList();
    MovieManager.instance.fetchGenres();

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

  void _resetHome() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    final manager = MovieManager.instance;
    manager.activeGenreFilters.clear();
    manager.filterActor = false;
    manager.filterDirector = false;
    manager.searchMovies('');
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
    manager.fetchNextPageMovies(initial: true);
    setState(() {});
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SearchFilterModal(
        onApply: () =>
            MovieManager.instance.searchMovies(_searchController.text),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          "Create New List",
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: "List Name (e.g. Watchlist)",
            hintStyle: TextStyle(color: AppTheme.textColor.withAlpha(128)),
            filled: true,
            fillColor: Colors.black26,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await MovieManager.instance.createCustomList(
                  nameController.text.trim(),
                  'movies',
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("List created carefully!")),
                  );
                }
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddToListSheet(BuildContext context, Movie movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add to List: ${movie.title}",
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Divider(color: AppTheme.textColor.withAlpha(51)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: AppTheme.primaryBlue),
                ),
                title: Text(
                  "Create New List",
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateListDialog(context);
                },
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue,
                        ),
                      );
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "You have no lists yet.",
                          style: TextStyle(
                            color: AppTheme.textColor.withAlpha(128),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['type'] != null &&
                            data['type'] != 'movies' &&
                            data['type'] != 'movie') {
                          return const SizedBox.shrink();
                        }
                        final items = data['items'] as List? ?? [];
                        final bool alreadyAdded = items.any(
                          (m) => m['id'] == movie.id,
                        );
                        return ListTile(
                          leading: Icon(Icons.list, color: AppTheme.iconColor),
                          title: Text(
                            data['name'] ?? 'Untitled',
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                          subtitle: Text(
                            "${items.length} movies",
                            style: TextStyle(
                              color: AppTheme.textColor.withAlpha(153),
                            ),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.add, color: AppTheme.primaryBlue),
                          onTap: () async {
                            if (!alreadyAdded) {
                              await MovieManager.instance.addMovieToCustomList(
                                doc.id,
                                movie,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Added to list!"),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // [DÜZELTME]: AnimatedBuilder en dışta, Scaffold içinde.
    return AnimatedBuilder(
      animation: MovieManager.instance,
      builder: (context, child) {
        final manager = MovieManager.instance;
        final isDark = manager.isDarkMode;
        // Arama veya filtre aktif mi?
        final isSearching =
            _searchController.text.isNotEmpty ||
            manager.activeGenreFilters.isNotEmpty ||
            manager.filterActor ||
            manager.filterDirector;

        return Scaffold(
          // Rengi buradan dinamik alıyoruz
          backgroundColor: AppTheme.backgroundBlack,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. HEADER (SliverAppBar)
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                floating: true,
                elevation: 0,
                backgroundColor: AppTheme.backgroundBlack,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue.withAlpha(isDark ? 77 : 38),
                        AppTheme.backgroundBlack,
                      ],
                    ),
                  ),
                ),
                title: GestureDetector(
                  onTap: _resetHome,
                  child: Row(
                    children: [
                      Icon(
                        Icons.movie_filter_rounded,
                        color: AppTheme.primaryBlue,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "MyMovieList",
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () => context.push(AppRouters.profile),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue.withAlpha(128),
                            width: 2,
                          ),
                        ),
                        child: StreamBuilder<int>(
                          stream: MovieManager.instance
                              .getCurrentUserIconIndex(),
                          builder: (context, snapshot) {
                            final index = snapshot.data ?? 0;
                            return CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              backgroundImage: NetworkImage(
                                MovieManager.instance.profileIcons[index],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. ARAMA ÇUBUĞU
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: AppTheme.textColor),
                            decoration: InputDecoration(
                              hintText: "Movie, Actor, Director...",
                              hintStyle: TextStyle(
                                color: AppTheme.textColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppTheme.primaryBlue,
                              ),
                              suffixIcon: isSearching
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: _resetHome,
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                (manager.activeGenreFilters.isNotEmpty ||
                                    manager.filterActor ||
                                    manager.filterDirector)
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color:
                                (manager.activeGenreFilters.isNotEmpty ||
                                    manager.filterActor ||
                                    manager.filterDirector)
                                ? AppTheme.primaryBlue
                                : AppTheme.textColor,
                          ),
                          onPressed: _showFilterDialog,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. İÇERİK (Liste veya Arama Sonuçları)
              if (isSearching) ...[
                if (manager.searchResults.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Center(
                        child: Text(
                          "No results found.",
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = manager.searchResults[index];
                        if (item is Person) return PersonCard(person: item);
                        return MovieCard(movie: item as Movie, isGrid: true);
                      }, childCount: manager.searchResults.length),
                    ),
                  ),
              ] else ...[
                // TRENDING HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Trending Movies",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CAROUSEL
                if (manager.trendingMovies.isNotEmpty)
                  SliverToBoxAdapter(
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 380.0,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        viewportFraction: 0.65,
                        autoPlayInterval: const Duration(seconds: 6),
                        enableInfiniteScroll: true,
                      ),
                      items: manager.trendingMovies.map((movie) {
                        return GestureDetector(
                          onTap: () =>
                              context.push('/movie-detail', extra: movie),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: movie.poster,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) =>
                                      Container(color: AppTheme.surfaceDark),
                                  errorWidget: (c, u, e) =>
                                      Container(color: Colors.grey),
                                ),
                                // [DÜZELTME]: Siyah gölge yerine Tema Rengi
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        AppTheme.backgroundBlack.withValues(
                                          alpha: 1.0,
                                        ),
                                      ],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 10,
                                  right: 10,
                                  child: Text(
                                    movie.title,
                                    style: TextStyle(
                                      color: AppTheme.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: AppTheme.backgroundBlack,
                                          blurRadius: 10,
                                        ),
                                      ],
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

                // POPULAR HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Popular Movies",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // POPULAR LIST (Dikey)
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
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Hero(
                                    tag: 'movie_${movie.id}',
                                    child: CachedNetworkImage(
                                      imageUrl: movie.poster,
                                      width: 80,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 200,
                                      placeholder: (c, u) => Container(
                                        width: 80,
                                        height: 120,
                                        color: AppTheme.backgroundBlack,
                                      ),
                                      errorWidget: (c, u, e) => Container(
                                        width: 80,
                                        height: 120,
                                        color: Colors.grey,
                                      ),
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
                                        style: TextStyle(
                                          color: AppTheme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          Text(
                                            " ${movie.rating.toStringAsFixed(1)}",
                                            style: TextStyle(
                                              color: AppTheme.textColor
                                                  .withValues(alpha: 0.7),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (movie.genres.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            movie.genres.first,
                                            style: TextStyle(
                                              color: AppTheme.primaryBlue,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        manager.isFavorite(movie)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: manager.isFavorite(movie)
                                            ? Colors.red
                                            : AppTheme.iconColor.withValues(
                                                alpha: 0.5,
                                              ),
                                      ),
                                      onPressed: () =>
                                          manager.toggleFavorite(movie),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.playlist_add,
                                        color: AppTheme.iconColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _showAddToListSheet(context, movie),
                                    ),
                                  ],
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ],
          ),
        );
      },
    );
  }
}
