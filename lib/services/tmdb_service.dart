// Dosya: lib/services/tmdb_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';

// API Sabitleri
const String _API_KEY = "cea49e6756dd9655a98066426a1b934d";
const String _BASE_URL = "https://api.themoviedb.org/3";

class TmdbService {
  // Singleton (Tekil) Yapı
  static final TmdbService instance = TmdbService._privateConstructor();
  TmdbService._privateConstructor();

  // 1. Türleri Getir
  Future<Map<int, String>> fetchGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$_BASE_URL/genre/movie/list?api_key=$_API_KEY'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {for (var g in data['genres']) g['id']: g['name']};
      }
    } catch (e) {
      print("Service Genre Error: $e");
    }
    return {};
  }

  // 2. Popüler Filmleri Getir
  Future<Map<String, dynamic>> fetchPopularMovies(
    int page,
    Map<int, String> genreMap,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_BASE_URL/movie/popular?api_key=$_API_KEY&page=$page'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Movie> movies = (data['results'] as List)
            .map((json) => Movie.fromTMDB(json, genreMap))
            .toList();
        return {'movies': movies, 'totalPages': data['total_pages'] ?? 1};
      }
    } catch (e) {
      print("Service Popular Error: $e");
    }
    return {'movies': <Movie>[], 'totalPages': 0};
  }

  // 3. Arama (Film ve Kişi)
  Future<Map<String, List<dynamic>>> searchMulti(
    String query,
    Map<int, String> genreMap,
  ) async {
    List<Movie> movies = [];
    List<Person> people = [];

    try {
      final response = await http.get(
        Uri.parse(
          '$_BASE_URL/search/multi?api_key=$_API_KEY&query=${Uri.encodeComponent(query)}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        for (var item in data['results']) {
          if (item['media_type'] == 'movie') {
            movies.add(Movie.fromTMDB(item, genreMap));
          } else if (item['media_type'] == 'person') {
            people.add(Person.fromTMDB(item));
          }
        }
      }
    } catch (e) {
      print("Service Search Error: $e");
    }

    return {'movies': movies, 'people': people};
  }

  // 4. Sadece Kişi Ara (Filtreleme için)
  Future<List<Person>> searchPersonOnly(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_BASE_URL/search/person?api_key=$_API_KEY&query=${Uri.encodeComponent(query)}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((item) => Person.fromTMDB(item))
            .toList();
      }
    } catch (e) {
      print("Service Person Search Error: $e");
    }
    return [];
  }

  // 5. Kişi Detayları ve Filmografisi
  Future<void> fetchPersonDetails(
    Person person,
    Map<int, String> genreMap,
  ) async {
    // Detay
    try {
      final res = await http.get(
        Uri.parse('$_BASE_URL/person/${person.id}?api_key=$_API_KEY'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        person.biography = data['biography'] ?? "";
        person.birthday = data['birthday'] ?? "";
        person.placeOfBirth = data['place_of_birth'] ?? "";
      }
    } catch (e) {
      print(e);
    }

    // Filmografi
    try {
      final res = await http.get(
        Uri.parse(
          '$_BASE_URL/person/${person.id}/movie_credits?api_key=$_API_KEY',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        List<Movie> movies = [];
        List<dynamic> cast = data['cast'] ?? [];
        List<dynamic> crew = data['crew'] ?? [];

        // Yönetmense sadece yönettikleri
        if (person.knownFor == 'Directing')
          crew = crew.where((c) => c['job'] == 'Director').toList();

        var allCredits = [...cast, ...crew];
        final ids = <int>{};
        for (var item in allCredits) {
          if (item['poster_path'] != null && ids.add(item['id'])) {
            movies.add(Movie.fromTMDB(item, genreMap));
          }
        }
        // Popülerliğe göre sırala
        movies.sort((a, b) => b.popularity.compareTo(a.popularity));
        person.filmography = movies;
      }
    } catch (e) {
      print(e);
    }
  }

  // 6. Film Detayları (Cast ve Trailer)
  Future<void> fetchMovieExtras(Movie movie) async {
    // Cast (Oyuncular)
    try {
      final res = await http.get(
        Uri.parse('$_BASE_URL/movie/${movie.id}/credits?api_key=$_API_KEY'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        List<String> castNames = [];
        List<Map<String, String>> details = [];
        if (data['cast'] != null) {
          for (var actor in (data['cast'] as List).take(10)) {
            String name = actor['name'] ?? 'Unknown';
            castNames.add(name);
            String? pp = actor['profile_path'];
            String photo = pp != null
                ? "https://image.tmdb.org/t/p/w200$pp"
                : "";

            // --- DEĞİŞİKLİK BURADA: ID EKLENDİ ---
            // ID'yi String olarak saklıyoruz ki Map yapımız bozulmasın
            String personId = (actor['id'] ?? 0).toString();
            details.add({'name': name, 'photo': photo, 'id': personId});
            // -------------------------------------
          }
        }
        movie.actors = castNames;
        movie.castDetails = details;

        if (data['crew'] != null) {
          var dir = (data['crew'] as List).firstWhere(
            (c) => c['job'] == 'Director',
            orElse: () => null,
          );
          movie.director = dir != null ? dir['name'] : "Unknown";
          // Yönetmen ID'si için gerekirse buraya da ekleme yapılabilir ama şimdilik isim yeterli
        }
      }
    } catch (e) {
      print(e);
    }

    // Trailer (Aynı kalıyor)
    try {
      final res = await http.get(
        Uri.parse('$_BASE_URL/movie/${movie.id}/videos?api_key=$_API_KEY'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        var trailer = (data['results'] as List).firstWhere(
          (v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
          orElse: () => null,
        );
        movie.trailerId = trailer != null ? trailer['key'] : 'dQw4w9WgXcQ';
      }
    } catch (e) {
      print(e);
    }
  }

  // 7. ID ile Film Getir
  Future<Movie?> getMovieById(int id, Map<int, String> genreMap) async {
    try {
      final res = await http.get(
        Uri.parse('$_BASE_URL/movie/$id?api_key=$_API_KEY'),
      );
      if (res.statusCode == 200)
        return Movie.fromTMDB(json.decode(res.body), genreMap);
    } catch (e) {}
    return null;
  }

  // 8. Discover (Keşfet - Tür Filtresi İçin)
  Future<List<Movie>> discoverMoviesByGenre(
    String genreIds,
    Map<int, String> genreMap,
  ) async {
    try {
      final url =
          '$_BASE_URL/discover/movie?api_key=$_API_KEY&with_genres=$genreIds&sort_by=popularity.desc';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((json) => Movie.fromTMDB(json, genreMap))
            .toList();
      }
    } catch (e) {}
    return [];
  }
}
