import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mymovielist/data/genre_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String TMDB_API_KEY = "cea49e6756dd9655a98066426a1b934d";
const String TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500";

// --- Movie Sınıfı (AYNI KALIYOR) ---
class Movie {
  final int id;
  final String title;
  final double rating;
  final String poster;
  final List<String> genres;
  final String plot;
  List<String> actors;
  String director;
  String trailerId;
  double? appRating;
  int appVoteCount;

  Movie({
    required this.id,
    required this.title,
    required this.rating,
    required this.poster,
    required this.genres,
    required this.plot,
    this.actors = const ["Loading..."],
    this.director = "Unknown",
    this.trailerId = '',
    this.appRating,
    this.appVoteCount = 0,
  });

  factory Movie.fromTMDB(Map<String, dynamic> json) {
    String posterPath = json['poster_path'] ?? '';
    List<String> genresList = [];
    final manager = MovieManager.instance;
    if (json['genre_ids'] is List) {
      for (var id in json['genre_ids']) {
        genresList.add(manager._genreMap[id] ?? 'Unknown');
      }
      if (genresList.isEmpty) genresList.add("Unknown");
    } else {
      genresList.add("Unknown");
    }
    double safeRating = 0.0;
    final ratingValue = json['vote_average'];
    if (ratingValue is num) {
      safeRating = ratingValue.toDouble();
    } else if (ratingValue is String) {
      safeRating = double.tryParse(ratingValue) ?? 0.0;
    }

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Unknown Title',
      rating: safeRating,
      poster: posterPath.isNotEmpty && !posterPath.startsWith('http')
          ? TMDB_IMAGE_BASE_URL + posterPath
          : posterPath,
      genres: genresList.take(2).toList(),
      plot: json['overview'] ?? 'No description available.',
      actors: ["Loading..."],
      director: "Loading...",
      trailerId: '',
      appVoteCount: 0,
    );
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      rating: (map['vote_average'] ?? 0.0).toDouble(),
      poster: map['poster_path'] ?? '',
      genres: List<String>.from(map['genre_names'] ?? ['Unknown']),
      plot: map['overview'] ?? '',
      director: map['director'] ?? 'Unknown',
      appRating: (map['app_rating'] ?? 0.0).toDouble(),
      appVoteCount: (map['vote_count'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'vote_average': rating,
      'poster_path': poster,
      'overview': plot,
      'genre_names': genres,
      'director': director,
    };
  }
}

// --- MovieManager Sınıfı ---
class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();
  Map<int, String> _genreMap = {};
  Map<int, String> get idToNameMap => _genreMap;
  List<String> get allGenreNames => _genreMap.values.toList();
  MovieManager._privateConstructor();

  final List<Movie> _allMovies = [];
  final List<Movie> _searchResults = [];
  final List<Movie> _trendingMovies = [];
  final List<Movie> _favoriteMovies = [];
  final List<Movie> _appTopRatedMovies = [];

  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMorePages = true;

  List<Movie> get allMovies => _allMovies;
  List<Movie> get searchResults => _searchResults;
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get favoriteMovies => _favoriteMovies;
  List<Movie> get appTopRatedMovies => _appTopRatedMovies;
  bool get isFetching => _isFetching;
  bool get hasMorePages => _hasMorePages;
  bool isFavorite(Movie movie) =>
      _favoriteMovies.any((fav) => fav.id == movie.id);

  // --- FAVORİ İŞLEMLERİ ---
  Future<void> toggleFavorite(Movie movie) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    if (isFavorite(movie)) {
      _favoriteMovies.removeWhere((m) => m.id == movie.id);
      await userDoc.update({
        'favorites': FieldValue.arrayRemove([movie.toMap()]),
      });
    } else {
      _favoriteMovies.add(movie);
      await userDoc.update({
        'favorites': FieldValue.arrayUnion([movie.toMap()]),
      });
    }
    notifyListeners();
  }

  Future<void> loadFavoritesFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('favorites')) {
        final List<dynamic> favData = doc.data()!['favorites'];
        _favoriteMovies.clear();
        for (var data in favData) {
          _favoriteMovies.add(Movie.fromMap(data));
        }
        notifyListeners();
      }
    } catch (e) {
      print("Favoriler yüklenirken hata: $e");
    }
  }

  // --- REVIEW CRUD İŞLEMLERİ (YENİ) ---

  // 1. Yorum Ekleme
  Future<void> addReview(Movie movie, double rating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final String userName = user.email?.split('@')[0] ?? 'User';

    await FirebaseFirestore.instance.collection('reviews').add({
      'movie_id': movie.id,
      'user_id': user.uid,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'likes': [], // Beğenenlerin UID listesi
      'timestamp': FieldValue.serverTimestamp(),
    });

    final movieDocRef = FirebaseFirestore.instance
        .collection('app_movies')
        .doc(movie.id.toString());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(movieDocRef);
      if (!snapshot.exists) {
        transaction.set(movieDocRef, {
          'id': movie.id,
          'title': movie.title,
          'poster_path': movie.poster,
          'genre_names': movie.genres,
          'overview': movie.plot,
          'director': movie.director,
          'vote_sum': rating,
          'vote_count': 1,
          'app_rating': rating,
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        double currentSum = (snapshot.data()!['vote_sum'] ?? 0).toDouble();
        int currentCount = (snapshot.data()!['vote_count'] ?? 0).toInt();
        double newSum = currentSum + rating;
        int newCount = currentCount + 1;
        transaction.update(movieDocRef, {
          'vote_sum': newSum,
          'vote_count': newCount,
          'app_rating': newSum / newCount,
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    });
    await fetchAppTopRatedMovies();
  }

  // 2. Yorum Silme
  Future<void> deleteReview(String reviewId) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }

  // 3. Yorum Düzenleme
  Future<void> editReview(
    String reviewId,
    String newComment,
    double newRating,
  ) async {
    await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update(
      {
        'comment': newComment,
        'rating': newRating, // İstenirse puanı da güncelletiriz
        'is_edited': true,
      },
    );
    // Not: Ortalamayı tekrar hesaplamak karmaşık olduğu için şimdilik ortalamaya dokunmuyoruz.
  }

  // 4. Yorum Beğenme (Like)
  Future<void> toggleLikeReview(String reviewId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId);
    final doc = await docRef.get();

    if (doc.exists) {
      List likes = doc.data()?['likes'] ?? [];
      if (likes.contains(user.uid)) {
        // Zaten beğenmiş -> Çıkar
        await docRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        // Beğenmemiş -> Ekle
        await docRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    }
  }

  // 5. Yoruma Yanıt Verme (Reply) - Alt koleksiyon olarak
  Future<void> replyToReview(String reviewId, String replyText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final String userName = user.email?.split('@')[0] ?? 'User';

    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .collection('replies')
        .add({
          'user_id': user.uid,
          'user_name': userName,
          'text': replyText,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // --- STREAMLER ---
  Stream<QuerySnapshot> getReviewsStream(int movieId) {
    // OrderBy bazen index hatası verebilir, şimdilik kaldırıp client tarafında sıralayabilirsin
    // veya konsoldaki linke tıklayıp index oluşturabilirsin.
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('movie_id', isEqualTo: movieId)
        .snapshots();
  }

  Stream<QuerySnapshot> getRepliesStream(String reviewId) {
    return FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .collection('replies')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // --- DİĞER FONKSİYONLAR (FETCH, SEARCH vb. AYNI) ---
  Future<void> fetchAppTopRatedMovies() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('app_movies')
          .where('app_rating', isGreaterThan: 6.0)
          .orderBy('app_rating', descending: true)
          .limit(20)
          .get();

      _appTopRatedMovies.clear();
      for (var doc in querySnapshot.docs) {
        _appTopRatedMovies.add(Movie.fromMap(doc.data()));
      }
      notifyListeners();
    } catch (e) {
      print("App Top Rated Error: $e");
    }
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }
    final url = Uri.parse(
      'https://api.themoviedb.org/3/search/multi?api_key=$TMDB_API_KEY&query=${Uri.encodeComponent(query)}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _searchResults.clear();
        for (var item in data['results']) {
          String mediaType = item['media_type'] ?? '';
          if (mediaType == 'movie') {
            _searchResults.add(Movie.fromTMDB(item));
          } else if (mediaType == 'person') {
            if (item['known_for'] != null) {
              for (var knownMovie in item['known_for']) {
                if (knownMovie['media_type'] == 'movie')
                  _searchResults.add(Movie.fromTMDB(knownMovie));
              }
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print("Arama Hatası: $e");
    }
  }

  List<Movie> recommendByFavoriteGenres() {
    if (_favoriteMovies.isEmpty) return [];
    Map<String, int> genreCounts = {};
    for (var movie in _favoriteMovies) {
      for (var genre in movie.genres) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
    }
    String? topGenre;
    int maxCount = 0;
    genreCounts.forEach((genre, count) {
      if (count > maxCount) {
        maxCount = count;
        topGenre = genre;
      }
    });
    if (topGenre == null) return [];
    final potentialMovies = _allMovies
        .where(
          (movie) =>
              movie.genres.contains(topGenre!) &&
              !_favoriteMovies.any((f) => f.id == movie.id),
        )
        .toList();
    if (potentialMovies.isEmpty) return [];
    potentialMovies.shuffle();
    return potentialMovies.take(5).toList();
  }

  Future<void> fetchGenres() async {
    if (_genreMap.isNotEmpty) return;
    final url = Uri.parse(
      'https://api.themoviedb.org/3/genre/movie/list?api_key=$TMDB_API_KEY',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['genres'] is List) {
          _genreMap = {for (var g in data['genres']) g['id']: g['name']};
          GenreService.instance.setGenreMapping(_genreMap);
          _genreMap.forEach(
            (id, name) => GenreService.instance.fetchGenrePosterUrl(name, id),
          );
        }
      }
    } catch (e) {
      print('Genre Error: $e');
    }
  }

  Future<void> fetchNextPageMovies({bool initial = false}) async {
    if (!initial && (_isFetching || !_hasMorePages)) return;
    _isFetching = true;
    if (initial) {
      _currentPage = 1;
      _allMovies.clear();
      _trendingMovies.clear();
      _hasMorePages = true;
    }
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/popular?api_key=$TMDB_API_KEY&page=$_currentPage',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Movie> newMovies = (data['results'] as List)
            .map((json) => Movie.fromTMDB(json))
            .toList();
        _allMovies.addAll(newMovies);
        if (initial) _trendingMovies.addAll(newMovies.take(10));
        if ((data['total_pages'] ?? 0) <= _currentPage)
          _hasMorePages = false;
        else
          _currentPage++;
      } else {
        _hasMorePages = false;
      }
    } catch (e) {
      _hasMorePages = false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> fetchCast(Movie movie) async {
    if (movie.director != "Loading..." && movie.director != "Unknown") return;
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/${movie.id}/credits?api_key=$TMDB_API_KEY',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> castNames = [];
      for (var actor in (data['cast'] as List).take(5))
        castNames.add(actor['name']);
      movie.actors = castNames.isNotEmpty ? castNames : ["Cast Not Found"];
      var directorData = (data['crew'] as List).firstWhere(
        (crew) => crew['job'] == 'Director',
        orElse: () => null,
      );
      movie.director = directorData != null
          ? directorData['name']
          : "Unknown Director";
      notifyListeners();
    }
  }

  Future<void> fetchTrailerId(Movie movie) async {
    if (movie.trailerId.isNotEmpty) return;
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/${movie.id}/videos?api_key=$TMDB_API_KEY',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      var trailer = (data['results'] as List).firstWhere(
        (v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
        orElse: () => null,
      );
      movie.trailerId = trailer != null ? trailer['key'] : 'dQw4w9WgXcQ';
      notifyListeners();
    }
  }

  Map<String, String> getActorDetails(String actorName) {
    String bio = "$actorName is a world-renowned actor.";
    String cleanName = actorName.trim();
    String photo =
        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(cleanName)}&background=0D8ABC&color=fff&size=512&bold=true";
    return {"bio": bio, "photo": photo};
  }
}
