// Dosya: lib/data/movie_manager.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modeller
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';

// Servisler
import 'package:mymovielist/data/genre_service.dart';
import 'package:mymovielist/services/tmdb_service.dart';
import 'package:mymovielist/services/social_service.dart';

// Export
export 'package:mymovielist/models/movie_model.dart';
export 'package:mymovielist/models/person_model.dart';

class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();
  MovieManager._privateConstructor();

  // --- TEMA VE RENK AYARLARI ---
  bool isDarkMode = true; // Varsayılan: Karanlık
  int currentBgColor = 0xFF12141C;

  // 1. TEMAYI DEĞİŞTİR VE KAYDET
  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;

    // Rengi ayarla
    if (isDarkMode) {
      currentBgColor = 0xFF12141C; // Orijinal Dark
    } else {
      currentBgColor = 0xFFCFD8DC; // Yeni Mavi-Gri Light
    }

    notifyListeners(); // Arayüzü anlık güncelle

    // --- FIRESTORE'A KAYDET ---
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_dark_mode': isDarkMode,
      });
    }
  }

  // 2. KULLANICI GİRİŞ YAPINCA TEMAYI ÇEK (Login'de çağıracağız)
  Future<void> loadUserTheme() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Veritabanındaki tercihi al
        if (data.containsKey('is_dark_mode')) {
          isDarkMode = data['is_dark_mode'];

          // Rengi güncelle
          if (isDarkMode) {
            currentBgColor = 0xFF12141C;
          } else {
            currentBgColor = 0xFFCFD8DC;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Tema yüklenirken hata: $e");
    }
  }

  // 3. YENİ KULLANICI OLUŞTURURKEN VARSAYILAN TEMA EKLE
  Future<void> ensureUserExistsInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // Yeni kullanıcı oluştur
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'created_at': FieldValue.serverTimestamp(),
        'profile_icon_id': 0,
        'is_dark_mode': true, // Varsayılan Karanlık Mod
      });
    } else {
      // Kullanıcı zaten varsa, temasını yükle
      await loadUserTheme();
    }
  }

  // Sadece Arka Planı Değiştirme (Manuel Seçim)
  void changeBackgroundColor(int colorValue) {
    currentBgColor = colorValue;
    notifyListeners();
  }

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
    if (person.knownFor == 'Directing') {
      return _favoriteDirectors.any((p) => p.id == person.id);
    }
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

    if ((result['totalPages']) <= _currentPage) {
      _hasMorePages = false;
    } else {
      _currentPage++;
    }
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
        if (filterActor && !filterDirector) {
          _searchResults = people.where((p) => p.knownFor == 'Acting').toList();
        } else if (!filterActor && filterDirector) {
          _searchResults = people
              .where((p) => p.knownFor == 'Directing')
              .toList();
        } else {
          _searchResults = people;
        }
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
              )) {
            combined.add(m);
          }
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

  // --- FIREBASE İŞLEMLERİ ---

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
    final data = await _socialService.fetchAllFavorites();

    if (data.isNotEmpty) {
      if (data.containsKey('favorites_movies')) {
        _favoriteMovies.clear();
        final list = data['favorites_movies'] as List? ?? [];
        for (var item in list) {
          _favoriteMovies.add(Movie.fromMap(item));
        }
      } else if (data.containsKey('favorites')) {
        _favoriteMovies.clear();
        final list = data['favorites'] as List? ?? [];
        for (var item in list) {
          _favoriteMovies.add(Movie.fromMap(item));
        }
      }

      if (data.containsKey('favorites_actors')) {
        _favoriteActors.clear();
        final list = data['favorites_actors'] as List? ?? [];
        for (var item in list) {
          _favoriteActors.add(Person.fromTMDB(item));
        }
      }

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

  // --- LİSTE YÖNETİMİ ---
  // Listeleri Dinle
  Stream<QuerySnapshot> getUserListsStream() =>
      _socialService.getUserListsStream();

  // Yeni Liste Oluştur
  Future<void> createCustomList(String name, String type) async =>
      await _socialService.createList(name, type);

  // Listeye Film Ekle
  Future<void> addMovieToCustomList(String listId, Movie movie) async =>
      await _socialService.addToList(listId, movie.toMap());

  // Listeye Genel Öğe Ekle
  Future<void> addItemToCustomList(
    String listId,
    Map<String, dynamic> item,
  ) async => await _socialService.addToList(listId, item);

  // Listeden Film/Öğe Çıkar
  Future<void> removeMovieFromCustomList(
    String listId,
    Map<String, dynamic> item,
  ) async => await _socialService.removeFromList(listId, item);

  // Listeyi Sil
  Future<void> deleteCustomList(String listId) async =>
      await _socialService.deleteList(listId);

  // --- KULLANICI & PROFİL ---
  Future<void> ensureUserExists() async =>
      await _socialService.ensureUserExists();

  Future<void> updateProfileIcon(int iconIndex) async {
    await _socialService.updateProfileIcon(iconIndex);
    notifyListeners();
  }

  Stream<int> getCurrentUserIconIndex() =>
      _socialService.getUserIconIndexStream();

  Future<List<Map<String, dynamic>>> searchUsersByEmail(String q) =>
      _socialService.searchUsersByEmail(q);

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _socialService.changePassword(currentPassword, newPassword);
  }

  // --- ARKADAŞLIK & CHAT ---
  Stream<QuerySnapshot> getFriendsStream() => _socialService.getFriendsStream();
  Stream<QuerySnapshot> getFriendRequestsStream() =>
      _socialService.getFriendRequestsStream();

  Future<void> sendFriendRequest(String uid) async {
    await _socialService.sendFriendRequest(uid, "Unknown");
  }

  Future<void> acceptFriendRequest(String uid, String email) async =>
      await _socialService.acceptFriendRequest(uid, email);

  Future<void> removeFriend(String uid) async =>
      await _socialService.removeFriend(uid);

  void listenToFriendsList() {
    getFriendsStream().listen((snapshot) {
      _friendIds = snapshot.docs.map((d) => d.id).toSet();
      notifyListeners();
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

  // --- YORUMLAR (REVIEW) ---
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

  // --- ÖNERİLER ---
  Future<void> fetchAppTopRatedMovies() async {
    _appTopRatedMovies = await _socialService.fetchAppTopRatedMovies();
    notifyListeners();
  }

  List<Movie> recommendByFavoriteGenres() {
    if (_favoriteMovies.isEmpty) return [];
    Map<String, int> genreCounts = {};
    for (var m in _favoriteMovies) {
      for (var g in m.genres) {
        genreCounts[g] = (genreCounts[g] ?? 0) + 1;
      }
    }
    var sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var topGenres = sortedGenres.take(3).map((e) => e.key).toSet();

    return _allMovies
        .where((m) {
          bool hasGenre = m.genres.any((g) => topGenres.contains(g));
          bool alreadyFav = isFavorite(m);
          return hasGenre && !alreadyFav;
        })
        .take(10)
        .toList();
  }

  Future<void> renameCustomList(String listId, String newName) async =>
      await _socialService.renameList(listId, newName);

  Map<String, String> getActorDetails(String n) => {"bio": "...", "photo": ""};

  // --- GRUP ÖZELLİKLERİ (YENİ) ---

  // 1. Grup Oluştur
  Future<void> createGroup(String name, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('groups').add({
      'name': name,
      'description': description,
      'created_at': FieldValue.serverTimestamp(),
      'creator_id': user.uid,
      'members': [user.uid], // Kurucu direkt üye
      'pending_requests': [], // Katılmak isteyenler
    });
  }

  // 2. Grupları Getir (Stream)
  Stream<QuerySnapshot> getGroupsStream() {
    return FirebaseFirestore.instance
        .collection('groups')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // 3. Gruba Katılma İsteği Gönder
  Future<void> requestJoinGroup(String groupId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'pending_requests': FieldValue.arrayUnion([uid]),
    });
  }

  // 4. Üye İsteğini Onayla (Sadece Kurucu/Admin)
  Future<void> approveGroupMember(String groupId, String memberId) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'pending_requests': FieldValue.arrayRemove([memberId]),
      'members': FieldValue.arrayUnion([memberId]),
    });
  }

  // 5. Grup Mesajı Gönder
  Future<void> sendGroupMessage(String groupId, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
          'sender_id': user.uid,
          'sender_email': user.email,
          'text': text,
          'created_at': FieldValue.serverTimestamp(),
        });
  }

  // 6. Grup Mesajlarını Dinle
  Stream<QuerySnapshot> getGroupMessagesStream(String groupId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}
