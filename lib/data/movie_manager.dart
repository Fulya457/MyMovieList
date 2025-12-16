import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mymovielist/data/genre_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String TMDB_API_KEY = "cea49e6756dd9655a98066426a1b934d";
const String TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500";

// --- Movie Sınıfı ---
class Movie {
  final int id;
  final String title;
  final double rating;
  final String poster;
  final List<String> genres;
  final String plot;
  List<String> actors;
  String trailerId;

  Movie({
    required this.id,
    required this.title,
    required this.rating,
    required this.poster,
    required this.genres,
    required this.plot,
    this.actors = const ["Loading..."],
    this.trailerId = '',
  });

  factory Movie.fromTMDB(Map<String, dynamic> json) {
    String posterPath = json['poster_path'] ?? '';

    List<String> genresList = [];
    final manager = MovieManager.instance;

    if (json['genre_ids'] is List) {
      for (var id in json['genre_ids']) {
        final genreName = manager._genreMap[id] ?? 'Unknown';
        genresList.add(genreName);
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
      title: json['title'] ?? 'Unknown Title',
      rating: safeRating,
      poster: posterPath.isNotEmpty && !posterPath.startsWith('http')
          ? TMDB_IMAGE_BASE_URL + posterPath
          : posterPath,
      genres: genresList.take(2).toList(),
      plot: json['overview'] ?? 'No description available.',
      actors: ["Loading..."],
      trailerId: '',
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
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      rating: (map['vote_average'] ?? 0.0).toDouble(),
      poster: map['poster_path'] ?? '',
      genres: List<String>.from(map['genre_names'] ?? ['Unknown']),
      plot: map['overview'] ?? '',
    );
  }
}

// --- MovieManager Sınıfı ---
class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();

  Map<int, String> _genreMap = {};

  Map<int, String> get idToNameMap => _genreMap;
  List<String> get allGenreNames => _genreMap.values.toList();

  MovieManager._privateConstructor();

  final List<Movie> _allMovies = []; // Popüler filmler (Kaydırma ile gelenler)
  final List<Movie> _searchResults = []; // Arama sonuçları (YENİ)
  final List<Movie> _trendingMovies = [];
  final List<Movie> _favoriteMovies = [];

  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMorePages = true;

  List<Movie> get allMovies => _allMovies;
  List<Movie> get searchResults => _searchResults; // Getter eklendi
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get favoriteMovies => _favoriteMovies;
  bool get isFetching => _isFetching;
  bool get hasMorePages => _hasMorePages;

  bool isFavorite(Movie movie) {
    return _favoriteMovies.any((fav) => fav.id == movie.id);
  }

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

  // --- YENİ: API ÜZERİNDEN ARAMA YAPMA ---
  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    // Arama durumunda olduğumuzu belirtmek için isFetching true yapılabilir
    // ancak searchResults ayrı bir liste olduğu için UI'da bunu yönetmek daha kolay.

    final url = Uri.parse(
      'https://api.themoviedb.org/3/search/movie?api_key=$TMDB_API_KEY&query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _searchResults.clear();

        List<Movie> foundMovies = (data['results'] as List)
            .map((json) => Movie.fromTMDB(json))
            .toList();

        // Posteri olmayan veya çok düşük kaliteli sonuçları filtreleyebiliriz
        _searchResults.addAll(foundMovies);

        notifyListeners();
      }
    } catch (e) {
      print("Arama Hatası: $e");
    }
  }

  // --- ÖNERİLER ---
  List<Movie> get topRatedMovies {
    return _allMovies.where((movie) => movie.rating >= 7.5).toList();
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

    final potentialMovies = _allMovies.where((movie) {
      bool isAlreadyFav = _favoriteMovies.any((fav) => fav.id == movie.id);
      return movie.genres.contains(topGenre!) && !isAlreadyFav;
    }).toList();

    if (potentialMovies.isEmpty) return [];
    potentialMovies.shuffle();
    return potentialMovies.take(5).toList();
  }

  // --- VERİ ÇEKME ---
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
          _genreMap = {
            for (var genreJson in data['genres'])
              if (genreJson is Map<String, dynamic> &&
                  genreJson['id'] != null &&
                  genreJson['name'] != null)
                genreJson['id'] as int: genreJson['name'] as String,
          };
          GenreService.instance.setGenreMapping(_genreMap);
          _genreMap.forEach((id, name) {
            GenreService.instance.fetchGenrePosterUrl(name, id);
          });
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

        if (initial) {
          _trendingMovies.addAll(newMovies.take(10));
        }

        int totalPages = data['total_pages'] ?? 0;
        if (_currentPage >= totalPages)
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

  // --- DETAYLAR ---
  Future<void> fetchCast(Movie movie) async {
    if (movie.actors.isNotEmpty && movie.actors.first != "Loading...") return;
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/${movie.id}/credits?api_key=$TMDB_API_KEY',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> castNames = [];
      for (var actor in (data['cast'] as List).take(5)) {
        castNames.add(actor['name']);
      }
      movie.actors = castNames.isNotEmpty ? castNames : ["Cast Not Found"];
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
        (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer',
        orElse: () => null,
      );
      movie.trailerId = trailer != null ? trailer['key'] : 'dQw4w9WgXcQ';
      notifyListeners();
    }
  }

  Map<String, String> getActorDetails(String actorName) {
    String bio =
        "$actorName is a world-renowned actor known for their versatility and charismatic screen presence.";
    String cleanName = actorName.trim();
    String photo =
        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(cleanName)}&background=0D8ABC&color=fff&size=512&bold=true";
    return {"bio": bio, "photo": photo};
  }
}
