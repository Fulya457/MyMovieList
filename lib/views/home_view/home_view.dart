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

// Yeni Widget'ları Import Ediyoruz
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

  // Filtre penceresini açan fonksiyon (Artık harici dosyadan çağırıyor)
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
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add to List: ${movie.title}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.grey),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: MovieManager.instance.getUserListsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    final movieLists = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['type'] == 'movie' || data['type'] == null);
                    }).toList();

                    if (movieLists.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.playlist_add,
                              size: 50,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Henüz film listeniz yok.",
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push(AppRouters.profile);
                              },
                              child: const Text(
                                "Liste oluşturmak için tıklayın",
                                style: TextStyle(color: AppTheme.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: movieLists.length,
                      itemBuilder: (context, index) {
                        final listData =
                            movieLists[index].data() as Map<String, dynamic>;
                        final items =
                            listData['items'] as List? ??
                            listData['movies'] as List? ??
                            [];
                        final bool alreadyAdded = items.any(
                          (m) => m['id'] == movie.id,
                        );

                        return ListTile(
                          leading: const Icon(Icons.list, color: Colors.white),
                          title: Text(
                            listData['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            "${items.length} films",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check, color: Colors.green)
                              : const Icon(
                                  Icons.add,
                                  color: AppTheme.primaryBlue,
                                ),
                          onTap: () async {
                            if (!alreadyAdded) {
                              await MovieManager.instance.addMovieToCustomList(
                                movieLists[index].id,
                                movie,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${movie.title} listeye eklendi!",
                                    ),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: AnimatedBuilder(
        animation: MovieManager.instance,
        builder: (context, child) {
          final manager = MovieManager.instance;
          final isSearching =
              _searchController.text.isNotEmpty ||
              manager.activeGenreFilters.isNotEmpty ||
              manager.filterActor ||
              manager.filterDirector;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
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
                title: GestureDetector(
                  onTap: _resetHome,
                  child: const Row(
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
                            StreamBuilder<int>(
                              stream: MovieManager.instance
                                  .getCurrentUserIconIndex(),
                              builder: (context, snapshot) {
                                final index = snapshot.data ?? 0;
                                return CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: NetworkImage(
                                    MovieManager.instance.profileIcons[index],
                                  ),
                                );
                              },
                            ),
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
                  child: Row(
                    children: [
                      Expanded(
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
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _resetHome,
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
                      const SizedBox(width: 10),
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
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color:
                                (manager.activeGenreFilters.isNotEmpty ||
                                    manager.filterActor ||
                                    manager.filterDirector)
                                ? AppTheme.primaryBlue
                                : Colors.white,
                          ),
                          onPressed: _showFilterDialog,
                        ),
                      ),
                    ],
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
                        final item = manager.searchResults[index];
                        // --- KİŞİ İSE PERSON CARD ---
                        if (item is Person) return PersonCard(person: item);
                        // --- FİLM İSE MOVIE CARD (GRID) ---
                        return MovieCard(movie: item as Movie, isGrid: true);
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
                                Hero(
                                  tag: 'movie_${movie.id}',
                                  child: CachedNetworkImage(
                                    imageUrl: movie.poster,
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) =>
                                        Container(color: AppTheme.surfaceDark),
                                    errorWidget: (c, u, e) =>
                                        Container(color: Colors.grey),
                                  ),
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
                      // --- BURADA LİSTE GÖRÜNÜMÜ KULLANIYORUZ, AMA HALA CUSTOM ---
                      // MovieCard'ın liste modunu da kullanabiliriz veya eski yapıyı koruyabiliriz.
                      // HomeView'daki buton fonksiyonları (Favori vb.) MovieCard içine taşınmadığı için
                      // (Karmaşıklık olmasın diye), burada manuel yapı kurdum.
                      // İstersen MovieCard'ı tamamen buraya da entegre edebiliriz ama bu hali daha güvenli.
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
                                  child: Hero(
                                    tag: 'movie_${movie.id}',
                                    child: CachedNetworkImage(
                                      imageUrl: movie.poster,
                                      width: 70,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 150,
                                      placeholder: (c, u) => Container(
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
                                Column(
                                  children: [
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
                                    IconButton(
                                      icon: const Icon(
                                        Icons.playlist_add,
                                        color: Colors.white,
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
