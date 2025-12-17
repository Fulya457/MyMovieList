import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mymovielist/data/genre_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String TMDB_API_KEY = "cea49e6756dd9655a98066426a1b934d";
const String TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500";
const String TMDB_PROFILE_BASE_URL =
    "https://image.tmdb.org/t/p/w200"; // Oyuncu fotoları için

// --- Movie Sınıfı ---
class Movie {
  final int id;
  final String title;
  final double rating;
  final String poster;
  final List<String> genres;
  final String plot;

  // ESKİSİ: Sadece isim listesi
  List<String> actors;

  // YENİ: İsim ve Resim tutan detaylı liste
  List<Map<String, String>> castDetails;

  String director;
  String trailerId;
  double? appRating;
  int appVoteCount;
  final double popularity;
  final String releaseDate;

  Movie({
    required this.id,
    required this.title,
    required this.rating,
    required this.poster,
    required this.genres,
    required this.plot,
    this.actors = const ["Loading..."],
    this.castDetails = const [], // Başlangıçta boş
    this.director = "Unknown",
    this.trailerId = '',
    this.appRating,
    this.appVoteCount = 0,
    this.popularity = 0.0,
    this.releaseDate = "Unknown Date",
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

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Unknown Title',
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      poster: posterPath.isNotEmpty ? TMDB_IMAGE_BASE_URL + posterPath : '',
      genres: genresList.take(2).toList(),
      plot: json['overview'] ?? 'No description available.',
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      releaseDate: json['release_date'] ?? 'Unknown Date',
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
      popularity: 0.0,
      releaseDate: map['release_date'] ?? 'Unknown Date',
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
      'release_date': releaseDate,
    };
  }
}

// --- MovieManager Sınıfı ---
class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();

  Map<int, String> _genreMap = {};
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

  bool isFavorite(Movie movie) =>
      _favoriteMovies.any((fav) => fav.id == movie.id);

  // --- KULLANICI & PROFİL ---
  Future<void> ensureUserExistsInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email?.toLowerCase(),
        'created_at': FieldValue.serverTimestamp(),
        'favorites': [],
        'profile_icon_id': 0,
      });
    }
  }

  Future<void> updateProfileIcon(int iconIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profile_icon_id': iconIndex,
    });
    notifyListeners();
  }

  Stream<int> getCurrentUserIconIndex() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data()!.containsKey('profile_icon_id')) {
            return doc.data()!['profile_icon_id'] as int;
          }
          return 0;
        });
  }

  Future<List<Map<String, dynamic>>> searchUsersByEmail(
    String emailQuery,
  ) async {
    final query = emailQuery.toLowerCase().trim();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: query)
        .get();
    List<Map<String, dynamic>> users = [];
    final currentUser = FirebaseAuth.instance.currentUser;
    for (var doc in snapshot.docs) {
      if (doc.id == currentUser?.uid) continue;
      users.add({'uid': doc.id, 'email': doc.data()['email']});
    }
    return users;
  }

  Future<void> sendFriendRequest(String targetUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('friend_requests')
        .doc(currentUser.uid)
        .set({
          'from_uid': currentUser.uid,
          'email': currentUser.email,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> acceptFriendRequest(
    String requesterUid,
    String requesterEmail,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterUid)
        .collection('friends')
        .doc(currentUser.uid)
        .set({
          'uid': currentUser.uid,
          'email': currentUser.email,
          'since': FieldValue.serverTimestamp(),
        });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .doc(requesterUid)
        .set({
          'uid': requesterUid,
          'email': requesterEmail,
          'since': FieldValue.serverTimestamp(),
        });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('friend_requests')
        .doc(requesterUid)
        .delete();
  }

  Future<void> removeFriend(String friendUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .doc(friendUid)
        .delete();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(currentUser.uid)
        .delete();

    final chatId = getChatId(currentUser.uid, friendUid);
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messages = await chatRef.collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    await chatRef.delete();
  }

  Stream<QuerySnapshot> getFriendsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots();
  }

  Stream<QuerySnapshot> getFriendRequestsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friend_requests')
        .snapshots();
  }

  String getChatId(String userA, String userB) =>
      userA.compareTo(userB) < 0 ? "${userA}_$userB" : "${userB}_$userA";

  Future<void> sendMessage({
    required String receiverUid,
    required String text,
    Movie? sharedMovie,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final chatId = getChatId(currentUser.uid, receiverUid);
    Map<String, dynamic> messageData = {
      'sender_id': currentUser.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    };
    if (sharedMovie != null) {
      messageData['movie_id'] = sharedMovie.id;
      messageData['movie_title'] = sharedMovie.title;
      messageData['poster_path'] = sharedMovie.poster;
    }
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);
  }

  Stream<QuerySnapshot> getMessagesStream(String receiverUid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();
    final chatId = getChatId(currentUser.uid, receiverUid);
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Map<String, String> getActorDetails(String actorName) {
    String bio =
        "$actorName is a world-renowned actor known for their versatility and depth in various roles.";
    String cleanName = actorName.trim();
    String photo =
        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(cleanName)}&background=0D8ABC&color=fff&size=512&bold=true";
    return {"bio": bio, "photo": photo};
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
        for (var data in favData) _favoriteMovies.add(Movie.fromMap(data));
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Stream<DocumentSnapshot> getMovieLiveRating(int movieId) => FirebaseFirestore
      .instance
      .collection('app_movies')
      .doc(movieId.toString())
      .snapshots();

  Future<void> addReview(Movie movie, double newRating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userName = user.email?.split('@')[0] ?? 'User';
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    int profileIconId = 0;
    if (userDoc.exists && userDoc.data()!.containsKey('profile_icon_id')) {
      profileIconId = userDoc.data()!['profile_icon_id'];
    }

    final previousReviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('movie_id', isEqualTo: movie.id)
        .where('user_id', isEqualTo: user.uid)
        .get();
    double oldRating = 0.0;
    bool hasRated = false;
    if (previousReviews.docs.isNotEmpty) {
      hasRated = true;
      oldRating = (previousReviews.docs.first.data()['rating'] ?? 0).toDouble();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var d in previousReviews.docs)
        batch.update(d.reference, {
          'rating': newRating,
          'profile_icon_id': profileIconId,
        });
      await batch.commit();
    }
    await FirebaseFirestore.instance.collection('reviews').add({
      'movie_id': movie.id,
      'movie_title': movie.title,
      'poster_path': movie.poster,
      'user_id': user.uid,
      'user_name': userName,
      'profile_icon_id': profileIconId,
      'rating': newRating,
      'comment': comment,
      'likes': [],
      'timestamp': FieldValue.serverTimestamp(),
    });
    final movieRef = FirebaseFirestore.instance
        .collection('app_movies')
        .doc(movie.id.toString());
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(movieRef);
      if (!snap.exists) {
        tx.set(movieRef, {
          'id': movie.id,
          'title': movie.title,
          'poster_path': movie.poster,
          'vote_sum': newRating,
          'vote_count': 1,
          'app_rating': newRating,
        });
      } else {
        double sum = (snap.data()!['vote_sum'] ?? 0).toDouble();
        int count = (snap.data()!['vote_count'] ?? 0).toInt();
        if (hasRated) {
          sum = sum - oldRating + newRating;
        } else {
          sum += newRating;
          count += 1;
        }
        tx.update(movieRef, {
          'vote_sum': sum,
          'vote_count': count,
          'app_rating': count > 0 ? sum / count : 0.0,
        });
      }
    });
    await _createNotification(
      recipientId: user.uid,
      message: "${movie.title} filmine yorum yaptın.",
      movieId: movie.id,
      type: 'comment',
    );
    await fetchAppTopRatedMovies();
  }

  Future<void> deleteReview(String reviewId) async {
    final doc = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .get();
    if (!doc.exists) return;
    int mid = doc.data()!['movie_id'];
    double rating = (doc.data()!['rating'] ?? 0).toDouble();
    final movieRef = FirebaseFirestore.instance
        .collection('app_movies')
        .doc(mid.toString());
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(movieRef);
      if (snap.exists) {
        double sum = (snap.data()!['vote_sum'] ?? 0).toDouble() - rating;
        int count = (snap.data()!['vote_count'] ?? 0).toInt() - 1;
        if (count < 0) count = 0;
        if (sum < 0) sum = 0;
        tx.update(movieRef, {
          'vote_sum': sum,
          'vote_count': count,
          'app_rating': count > 0 ? sum / count : 0.0,
        });
      }
    });
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete();
    await fetchAppTopRatedMovies();
    notifyListeners();
  }

  Future<void> editReview(String id, String comment, double r) async =>
      await FirebaseFirestore.instance.collection('reviews').doc(id).update({
        'comment': comment,
        'is_edited': true,
      });

  Future<void> toggleLikeReview(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('reviews').doc(id);
    final doc = await docRef.get();
    if (doc.exists) {
      List likes = doc.data()?['likes'] ?? [];
      if (likes.contains(user.uid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
        if (doc.data()?['user_id'] != user.uid) {
          _createNotification(
            recipientId: doc.data()?['user_id'],
            message: "Birisi yorumunu beğendi.",
            movieId: doc.data()?['movie_id'],
            type: 'like',
          );
        }
      }
    }
  }

  Future<void> replyToReview(String id, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final parent = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(id)
        .get();
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(id)
        .collection('replies')
        .add({
          'user_id': user.uid,
          'user_name': user.email!.split('@')[0],
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
    if (parent.exists && parent.data()?['user_id'] != user.uid) {
      _createNotification(
        recipientId: parent.data()?['user_id'],
        message: "Yorumuna cevap geldi.",
        movieId: parent.data()?['movie_id'],
        type: 'reply',
      );
    }
  }

  Future<void> _createNotification({
    required String recipientId,
    required String message,
    required int movieId,
    required String type,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipient_id': recipientId,
      'message': message,
      'movie_id': movieId,
      'type': type,
      'is_read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getReviewsStream(int movieId) => FirebaseFirestore
      .instance
      .collection('reviews')
      .where('movie_id', isEqualTo: movieId)
      .snapshots();
  Stream<QuerySnapshot> getRepliesStream(String reviewId) => FirebaseFirestore
      .instance
      .collection('reviews')
      .doc(reviewId)
      .collection('replies')
      .orderBy('timestamp')
      .snapshots();

  Future<Movie?> getMovieById(int id) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/movie/$id?api_key=$TMDB_API_KEY',
        ),
      );
      if (res.statusCode == 200) return Movie.fromTMDB(json.decode(res.body));
    } catch (e) {}
    return null;
  }

  Future<void> changePassword(String p) async =>
      await FirebaseAuth.instance.currentUser?.updatePassword(p);

  Future<void> fetchAppTopRatedMovies() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('app_movies')
          .where('app_rating', isGreaterThan: 6.0)
          .orderBy('app_rating', descending: true)
          .limit(20)
          .get();
      _appTopRatedMovies.clear();
      for (var d in qs.docs) _appTopRatedMovies.add(Movie.fromMap(d.data()));
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/search/multi?api_key=$TMDB_API_KEY&query=${Uri.encodeComponent(query)}',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _searchResults.clear();
      for (var item in data['results']) {
        final mediaType = item['media_type'];
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
      final ids = <int>{};
      final uniqueMovies = <Movie>[];
      for (var movie in _searchResults) {
        if (ids.add(movie.id)) {
          uniqueMovies.add(movie);
        }
      }
      uniqueMovies.sort((a, b) => b.popularity.compareTo(a.popularity));
      _searchResults.clear();
      _searchResults.addAll(uniqueMovies);
      notifyListeners();
    }
  }

  Future<void> fetchGenres() async {
    if (_genreMap.isNotEmpty) return;
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/genre/movie/list?api_key=$TMDB_API_KEY',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _genreMap = {for (var g in data['genres']) g['id']: g['name']};
      GenreService.instance.setGenreMapping(_genreMap);
      _genreMap.forEach(
        (id, name) => GenreService.instance.fetchGenrePosterUrl(name, id),
      );
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
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/movie/popular?api_key=$TMDB_API_KEY&page=$_currentPage',
      ),
    );
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
    _isFetching = false;
    notifyListeners();
  }

  // --- BURASI GÜNCELLENDİ: FOTOĞRAFLARI DA ÇEKİYOR ---
  Future<void> fetchCast(Movie movie) async {
    if (movie.director != "Unknown") return;
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/movie/${movie.id}/credits?api_key=$TMDB_API_KEY',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> castNames = [];
      List<Map<String, String>> details = [];

      for (var actor in (data['cast'] as List).take(10)) {
        String name = actor['name'];
        castNames.add(name);

        // Fotoğraf yolunu al ve tam URL oluştur
        String? profilePath = actor['profile_path'];
        String photoUrl = profilePath != null
            ? "$TMDB_PROFILE_BASE_URL$profilePath"
            : ""; // Foto yoksa boş string

        details.add({'name': name, 'photo': photoUrl});
      }

      movie.actors = castNames;
      movie.castDetails = details; // Detaylı listeyi kaydet

      var dir = (data['crew'] as List).firstWhere(
        (c) => c['job'] == 'Director',
        orElse: () => null,
      );
      movie.director = dir != null ? dir['name'] : "Unknown";
      notifyListeners();
    }
  }

  Future<void> fetchTrailerId(Movie movie) async {
    if (movie.trailerId.isNotEmpty) return;
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/movie/${movie.id}/videos?api_key=$TMDB_API_KEY',
      ),
    );
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
}
