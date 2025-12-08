import 'package:flutter/material.dart';

class Movie {
  final int id;
  final String title;
  final double rating;
  final String poster;
  final List<String> genres;
  final String plot;
  final List<String> actors;
  final String trailerId;

  Movie({
    required this.id,
    required this.title,
    required this.rating,
    required this.poster,
    required this.genres,
    required this.plot,
    required this.actors,
    required this.trailerId,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      poster: json['poster'] ?? 'https://via.placeholder.com/150',
      genres: (json['genre'] as List?)?.map((e) => e.toString()).toList() ?? ['General'],
      plot: json['plot'] ?? 'No description available.',
      actors: (json['actors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      trailerId: json['trailerId'] ?? '',
    );
  }
}

class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();
  MovieManager._privateConstructor();

  // --- LİSTELER ---
  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];
  final List<Movie> _favoriteMovies = [];

  // --- GETTER'LAR (Dışarıdan Erişim) ---
  List<Movie> get allMovies => _allMovies;
  List<Movie> get trendingMovies => _trendingMovies;
  
  // İŞTE EKSİK OLAN SATIR BUYDU:
  List<Movie> get favoriteMovies => _favoriteMovies; 

  // --- FONKSİYONLAR ---
  
  void setMovies(List<Movie> movies) {
    _allMovies = movies;
    notifyListeners();
  }

  void setTrendingMovies(List<Movie> movies) {
    _trendingMovies = movies;
    notifyListeners();
  }

  void toggleFavorite(Movie movie) {
    if (_favoriteMovies.contains(movie)) {
      _favoriteMovies.remove(movie);
    } else {
      _favoriteMovies.add(movie);
    }
    notifyListeners();
  }

  bool isFavorite(Movie movie) {
    return _favoriteMovies.contains(movie);
  }
}