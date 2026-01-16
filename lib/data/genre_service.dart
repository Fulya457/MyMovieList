// Dosya: lib/data/genre_service.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mymovielist/data/movie_manager.dart'; // Manager'a erişim

const String _API_KEY = "cea49e6756dd9655a98066426a1b934d";
const String _IMAGE_BASE = "https://image.tmdb.org/t/p/w500";

class GenreState {
  List<Movie> movies = [];
  int currentPage = 1;
  bool isFetching = false;
  bool hasMorePages = true;
}

class GenreService extends ChangeNotifier {
  static final GenreService instance = GenreService._privateConstructor();
  GenreService._privateConstructor();

  final Map<String, GenreState> _genreStates = {};
  Map<String, int> _genreNameToId = {};

  final Map<String, String> _genrePosterUrls = {};
  Map<String, String> get genrePosterUrls => _genrePosterUrls;

  GenreState getGenreState(String genreName) {
    if (!_genreStates.containsKey(genreName)) {
      _genreStates[genreName] = GenreState();
    }
    return _genreStates[genreName]!;
  }

  void setGenreMapping(Map<int, String> idToNameMap) {
    _genreNameToId = idToNameMap.map((id, name) => MapEntry(name, id));
    notifyListeners();
  }

  Future<void> fetchGenrePosterUrl(String genreName, int genreId) async {
    if (_genrePosterUrls.containsKey(genreName)) return;

    final url = Uri.parse(
      'https://api.themoviedb.org/3/discover/movie?api_key=$_API_KEY&with_genres=$genreId&sort_by=popularity.desc&page=1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          final posterPath = results[0]['poster_path'];
          if (posterPath != null) {
            _genrePosterUrls[genreName] = _IMAGE_BASE + posterPath;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print("Genre Poster Error: $e");
    }
  }

  Future<void> fetchNextPageGenreMovies(
    String genreName, {
    bool initial = false,
  }) async {
    final state = getGenreState(genreName);

    if (initial) {
      state.currentPage = 1;
      state.movies.clear();
      state.hasMorePages = true;
      state.isFetching = false;
    }

    if (state.isFetching || !state.hasMorePages) return;

    state.isFetching = true;

    final genreId = _genreNameToId[genreName];
    if (genreId == null) {
      state.isFetching = false;
      return;
    }

    final url = Uri.parse(
      'https://api.themoviedb.org/3/discover/movie?api_key=$_API_KEY&with_genres=$genreId&page=${state.currentPage}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Movie> newMovies = (data['results'] as List)
            .map((json) => Movie.fromTMDB(json, MovieManager.instance.genreMap))
            .toList();

        state.movies.addAll(newMovies);

        int totalPages = data['total_pages'] ?? 0;
        if (state.currentPage >= totalPages || newMovies.isEmpty) {
          state.hasMorePages = false;
        } else {
          state.currentPage++;
        }
      } else {
        state.hasMorePages = false;
      }
    } catch (e) {
      print('Genre connection error: $e');
    } finally {
      state.isFetching = false;
      notifyListeners();
    }
  }
}
