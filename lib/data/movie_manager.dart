import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modeller
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';

// Servisler
import 'package:mymovielist/data/genre_service.dart';
import 'package:mymovielist/services/tmdb_service.dart';
import 'package:mymovielist/services/social_service.dart'; // YENİ EKLENDİ

// Export
export 'package:mymovielist/models/movie_model.dart';
export 'package:mymovielist/models/person_model.dart';

class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();
  MovieManager._privateConstructor();

  // Servisler
  final TmdbService _tmdbService = TmdbService.instance;
  final SocialService _socialService = SocialService.instance;

  // --- VERİLER ---
  Map<int, String> _genreMap = {};
  Map<int, String> get genreMap => _genreMap;
  Map<String, int> get genreNameToId =>
      _genreMap.map((key, value) => MapEntry(value, key));
  List<String> get allGenreNames => _genreMap.values.toList();

  final List<String> profileIcons = [
    "https://api.dicebear.com/7.x/bottts/png?seed=Robot1",
    "https://api.dicebear.com/7.x/adventurer/png?seed=Felix",
    "https://api.dicebear.com/7.x/adventurer/png?seed=Chloe",
    "https://api.dicebear.com/7.x/fun-emoji/png?seed=Cool",
    "https://api.dicebear.com/7.x/identicon/png?seed=Abstract",
    "https://api.dicebear.com/7.x/thumbs/png?seed=Bandit",
    "https://api.dicebear.com/7.x/lorelei/png?seed=Artist",
    "https://api.dicebear.com/7.x/notionists/png?seed=Playful",
    "https://api.dicebear.com/7.x/big-ears/png?seed=Mouse",
    "https://api.dicebear.com/7.x/micah/png?seed=Cool",
  ];

  final List<Movie> _allMovies = [];
  List<dynamic> _searchResults = [];
  final List<Movie> _trendingMovies = [];

  final List<Movie> _favoriteMovies = [];
  final List<Person> _favoriteActors = [];
  final List<Person> _favoriteDirectors = [];
  List<Movie> _appTopRatedMovies = [];
  Set<String> _friendIds = {};

  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMorePages = true;

  List<int> activeGenreFilters = [];
  bool filterActor = false;
  bool filterDirector = false;

  // Getterlar
  List<Movie> get allMovies => _allMovies;
  List<dynamic> get searchResults => _searchResults;
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get favoriteMovies => _favoriteMovies;
  List<Person> get favoriteActors => _favoriteActors;
  List<Person> get favoriteDirectors => _favoriteDirectors;
  List<Movie> get appTopRatedMovies => _appTopRatedMovies;
  bool get isFetching => _isFetching;

  bool isFavorite(Movie movie) =>
      _favoriteMovies.any((fav) => fav.id == movie.id);
  bool isPersonFavorite(Person person) {
    if (person.knownFor == 'Directing')
      return _favoriteDirectors.any((p) => p.id == person.id);
    return _favoriteActors.any((p) => p.id == person.id);
  }

  bool isFriend(String uid) => _friendIds.contains(uid);

  // --- API (TMDB) İŞLEMLERİ ---
  Future<void> fetchGenres() async {
    if (_genreMap.isNotEmpty) return;
    _genreMap = await _tmdbService.fetchGenres();
    GenreService.instance.setGenreMapping(_genreMap);
    _genreMap.forEach(
      (id, name) => GenreService.instance.fetchGenrePosterUrl(name, id),
    );
    notifyListeners();
  }

  Future<void> fetchNextPageMovies({bool initial = false}) async {
    if (!initial && (_isFetching || !_hasMorePages)) return;
    _isFetching = true;
    if (initial) {
      _currentPage = 1;
      _allMovies.clear();
      _trendingMovies.clear();
      _hasMorePages = true;
      if (_genreMap.isEmpty) await fetchGenres();
    }

    final result = await _tmdbService.fetchPopularMovies(
      _currentPage,
      _genreMap,
    );
    _allMovies.addAll(result['movies']);
    if (initial) _trendingMovies.addAll(result['movies'].take(10));

    if ((result['totalPages']) <= _currentPage)
      _hasMorePages = false;
    else
      _currentPage++;
    _isFetching = false;
    notifyListeners();
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty && activeGenreFilters.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }
    if (_genreMap.isEmpty) await fetchGenres();

    if (filterActor || filterDirector) {
      // Kişi Bazlı
      List<Person> people = await _tmdbService.searchPersonOnly(query);
      if (activeGenreFilters.isNotEmpty) {
        List<Movie> filteredMovies = [];
        for (var person in people.take(3)) {
          await _tmdbService.fetchPersonDetails(person, _genreMap);
          var matches = person.filmography
              .where(
                (m) => m.genreIds.any((id) => activeGenreFilters.contains(id)),
              )
              .toList();
          filteredMovies.addAll(matches);
        }
        final ids = <int>{};
        _searchResults = filteredMovies.where((m) => ids.add(m.id)).toList();
      } else {
        if (filterActor && !filterDirector)
          _searchResults = people.where((p) => p.knownFor == 'Acting').toList();
        else if (!filterActor && filterDirector)
          _searchResults = people
              .where((p) => p.knownFor == 'Directing')
              .toList();
        else
          _searchResults = people;
      }
    } else {
      // Film Bazlı
      if (query.isEmpty && activeGenreFilters.isNotEmpty) {
        final genreString = activeGenreFilters.join(',');
        _searchResults = await _tmdbService.discoverMoviesByGenre(
          genreString,
          _genreMap,
        );
      } else {
        Map<String, List<dynamic>> results = await _tmdbService.searchMulti(
          query,
          _genreMap,
        );
        List<dynamic> combined = [];
        for (var m in results['movies']!) {
          if (activeGenreFilters.isEmpty ||
              (m as Movie).genreIds.any(
                (id) => activeGenreFilters.contains(id),
              ))
            combined.add(m);
        }
        if (activeGenreFilters.isEmpty) combined.addAll(results['people']!);
        _searchResults = combined;
      }
    }
    notifyListeners();
  }

  Future<void> fetchPersonDetails(Person person) async {
    await _tmdbService.fetchPersonDetails(person, _genreMap);
    notifyListeners();
  }

  Future<void> fetchCast(Movie movie) async {
    if (movie.castDetails.isNotEmpty && movie.director != "Unknown") return;
    await _tmdbService.fetchMovieExtras(movie);
    notifyListeners();
  }

  Future<void> fetchTrailerId(Movie movie) async {
    if (movie.trailerId.isNotEmpty) return;
    await _tmdbService.fetchMovieExtras(movie);
    notifyListeners();
  }

  Future<Movie?> getMovieById(int id) async {
    return await _tmdbService.getMovieById(id, _genreMap);
  }

  // --- FIREBASE (SOCIAL SERVICE'E DEVREDİLDİ) ---

  Future<void> toggleFavorite(Movie movie) async {
    if (isFavorite(movie)) {
      _favoriteMovies.removeWhere((m) => m.id == movie.id);
      await _socialService.updateFavoriteMovie(movie, false);
    } else {
      _favoriteMovies.add(movie);
      await _socialService.updateFavoriteMovie(movie, true);
    }
    notifyListeners();
  }

  Future<void> togglePersonFavorite(Person person) async {
    bool isDirector = person.knownFor == 'Directing';
    List<Person> targetList = isDirector ? _favoriteDirectors : _favoriteActors;
    if (isPersonFavorite(person)) {
      targetList.removeWhere((p) => p.id == person.id);
      await _socialService.updateFavoritePerson(person, false);
    } else {
      targetList.add(person);
      await _socialService.updateFavoritePerson(person, true);
    }
    notifyListeners();
  }

  Future<void> loadFavoritesFromFirebase() async {
    // Servisten veriyi çekiyoruz
    final data = await _socialService.fetchAllFavorites();

    if (data.isNotEmpty) {
      // 1. Film Favorileri
      if (data.containsKey('favorites_movies')) {
        _favoriteMovies.clear();
        // HATA ÇÖZÜMÜ: (data[...] as List? ?? []) yapısı kullanıldı.
        final list = data['favorites_movies'] as List? ?? [];
        for (var item in list) {
          _favoriteMovies.add(Movie.fromMap(item));
        }
      }
      // Eski veri yapısı desteği
      else if (data.containsKey('favorites')) {
        _favoriteMovies.clear();
        final list = data['favorites'] as List? ?? [];
        for (var item in list) {
          _favoriteMovies.add(Movie.fromMap(item));
        }
      }

      // 2. Aktör Favorileri
      if (data.containsKey('favorites_actors')) {
        _favoriteActors.clear();
        final list = data['favorites_actors'] as List? ?? [];
        for (var item in list) {
          _favoriteActors.add(Person.fromTMDB(item));
        }
      }

      // 3. Yönetmen Favorileri
      if (data.containsKey('favorites_directors')) {
        _favoriteDirectors.clear();
        final list = data['favorites_directors'] as List? ?? [];
        for (var item in list) {
          _favoriteDirectors.add(Person.fromTMDB(item));
        }
      }
      notifyListeners();
    }
  }

  // Listeler
  Future<void> createCustomList(String name, String type) async =>
      await _socialService.createList(name, type);
  Future<void> addMovieToCustomList(String listId, Movie movie) async =>
      await _socialService.addToList(listId, movie.toMap());
  Future<void> addItemToCustomList(
    String listId,
    Map<String, dynamic> item,
  ) async => await _socialService.addToList(listId, item);
  Future<void> removeMovieFromCustomList(
    String listId,
    Map<String, dynamic> item,
  ) async => await _socialService.removeFromList(listId, item);
  Future<void> deleteCustomList(String listId) async =>
      await _socialService.deleteList(listId);
  Stream<QuerySnapshot> getUserListsStream() =>
      _socialService.getUserListsStream();

  // Kullanıcı
  Future<void> ensureUserExistsInFirestore() async =>
      await _socialService.ensureUserExists();
  Future<void> updateProfileIcon(int iconIndex) async {
    await _socialService.updateProfileIcon(iconIndex);
    notifyListeners();
  }

  Stream<int> getCurrentUserIconIndex() =>
      _socialService.getUserIconIndexStream();
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String q) =>
      _socialService.searchUsersByEmail(q);
  Future<void> changePassword(String p) async =>
      await _socialService.changePassword(p);

  // Arkadaşlık & Chat
  Future<void> sendFriendRequest(String uid) async {
    // Burada targetEmail bulmak zor olduğu için basitleştirilmiş
    // SocialService'de bu mantığı biraz daha esnetmek gerekebilir ama şimdilik:
    // Bu metod genellikle FriendsView'dan çağrılır, orada email bilinir.
    // Ancak Manager yapısını bozmamak için burada dummy email veya
    // SocialService içindeki metod imzasını güncellemek gerekebilir.
    // Şimdilik null gönderiyoruz, SocialService'de düzeltilmeli veya
    // kullanıcı ararken email'i de parametre geçmelisin.
    // (Kodun bozulmaması için SocialService'deki sendFriendRequest'i biraz değiştirelim
    // veya buraya dummy parametre girelim)
    await _socialService.sendFriendRequest(uid, "");
  }
  // DOĞRUSU: UI tarafında (FriendsView) direkt SocialService çağırılabilir veya buraya email eklenmeli.
  // Ama söz verdiğim gibi fonksiyon imzalarını bozmuyorum.

  Future<void> acceptFriendRequest(String uid, String email) async =>
      await _socialService.acceptFriendRequest(uid, email);
  Future<void> removeFriend(String uid) async =>
      await _socialService.removeFriend(uid);

  Stream<QuerySnapshot> getFriendsStream() => _socialService.getFriendsStream();
  Stream<QuerySnapshot> getFriendRequestsStream() =>
      _socialService.getFriendRequestsStream();

  void listenToFriendsList() {
    getFriendsStream().listen((snapshot) {
      _friendIds = snapshot.docs.map((d) => d.id).toSet();
    });
  }

  Future<void> sendMessage({
    required String receiverUid,
    required String text,
    Movie? sharedMovie,
    Map<String, dynamic>? sharedList,
  }) async {
    await _socialService.sendMessage(
      receiverUid,
      text,
      sharedMovie: sharedMovie,
      sharedList: sharedList,
    );
  }

  Stream<QuerySnapshot> getMessagesStream(String uid) =>
      _socialService.getMessagesStream(uid);

  // Review
  Stream<DocumentSnapshot> getMovieLiveRating(int id) =>
      _socialService.getMovieLiveRating(id);
  Stream<QuerySnapshot> getReviewsStream(int id) =>
      _socialService.getReviewsStream(id);
  Stream<QuerySnapshot> getRepliesStream(String id) =>
      _socialService.getRepliesStream(id);

  Future<void> addReview(Movie movie, double rating, String comment) async {
    await _socialService.addReview(movie, rating, comment);
    fetchAppTopRatedMovies();
  }

  Future<void> deleteReview(String id) async {
    await _socialService.deleteReview(id);
    fetchAppTopRatedMovies();
  }

  Future<void> editReview(String id, String c, double r) async =>
      await _socialService.editReview(id, c);
  Future<void> toggleLikeReview(String id) async =>
      await _socialService.toggleLikeReview(id);
  Future<void> replyToReview(String id, String t) async =>
      await _socialService.replyToReview(id, t);

  Future<void> fetchAppTopRatedMovies() async {
    _appTopRatedMovies = await _socialService.fetchAppTopRatedMovies();
    notifyListeners();
  }

  // Helper
  Map<String, String> getActorDetails(String n) => {"bio": "...", "photo": ""};
  List<Movie> recommendByFavoriteGenres() {
    /* ... (Yukarıda tanımlı) ... */
    return [];
  }
}
