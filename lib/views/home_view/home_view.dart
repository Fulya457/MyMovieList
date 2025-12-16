import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/app/theme.dart';
import 'dart:async'; // Timer için gerekli

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String searchQuery = "";
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  // YENİ: Debounce (Gecikme) için Timer
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final manager = MovieManager.instance;
    // Arama yaparken sonsuz kaydırmayı devre dışı bırakıyoruz
    if (searchQuery.isEmpty &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !manager.isFetching &&
        manager.hasMorePages) {
      manager.fetchNextPageMovies();
    }
  }

  Future<void> _loadData() async {
    try {
      await MovieManager.instance.fetchNextPageMovies(initial: true);
      await MovieManager.instance.loadFavoritesFromFirebase();
    } catch (e) {
      print('Movie loading error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // YENİ: Arama metnini yöneten fonksiyon
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });

    // Varsa önceki zamanlayıcıyı iptal et
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    // Yeni zamanlayıcı başlat (500ms sonra API isteği atar)
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      MovieManager.instance.searchMovies(query);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchDebounce?.cancel(); // Timer'ı temizle
    super.dispose();
  }

  String _getMemberName() {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Kullanıcı';
    if (email.contains('@')) {
      return email.substring(0, email.indexOf('@'));
    }
    return 'Kullanıcı';
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRouters.login);
  }

  Widget _homeAppBarContent(BuildContext context) {
    final memberName = _getMemberName();
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
                "MY MOVIE LIST",
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push(AppRouters.profile);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    memberName,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
        // YENİ: Arama sonuçlarını al
        final searchResults = MovieManager.instance.searchResults;
        final isFetching = MovieManager.instance.isFetching;
        final hasMore = MovieManager.instance.hasMorePages;

        // Arama yapılıyorsa gösterilecek liste: searchResults
        // Yapılmıyorsa: allMovies
        final moviesToShow = searchQuery.isNotEmpty ? searchResults : allMovies;

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
                      _homeAppBarContent(context),

                      // --- ARAMA KUTUSU (GÜNCELLENDİ) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged:
                              _onSearchChanged, // Yeni fonksiyon bağlandı
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
                            // Temizleme butonu eklendi
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      // Metni temizle ve aramayı sıfırla
                                      _onSearchChanged("");
                                      // Klavye odağını kaybetmek istersen: FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            hintText: 'Search movies (API)...',
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- EĞER ARAMA YAPILIYORSA TRENDLERİ GİZLE ---
                      if (searchQuery.isEmpty && !isLoading) ...[
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
                      ] else if (searchQuery.isNotEmpty) ...[
                        // Arama yapılırken başlık
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            "SEARCH RESULTS",
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      // --- YÜKLENİYOR ---
                      if (isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      else if (moviesToShow.isEmpty)
                        Center(
                          child: Text(
                            searchQuery.isNotEmpty
                                ? 'No movies found for "$searchQuery".'
                                : 'No movies found.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        // --- FİLM LİSTESİ (Arama veya Normal) ---
                        ...List.generate(moviesToShow.length, (index) {
                          final movie = moviesToShow[index];
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
                                    // Hatalı resim kontrolü
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.movie,
                                              color: Colors.grey,
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
                                  '${movie.genres.isNotEmpty ? movie.genres.first : 'Unknown'} • ⭐ ${movie.rating.toStringAsFixed(1)}',
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

                      // --- SAYFALAMA SADECE NORMAL MODDA ÇALIŞIR ---
                      if (isFetching && hasMore && searchQuery.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryBlue,
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
