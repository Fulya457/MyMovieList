import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mymovielist/data/genre_service.dart';

// TMDB API KEY ve URL'ler
// DİKKAT: Anahtarınızı değiştirmeyin.
const String TMDB_API_KEY = "cea49e6756dd9655a98066426a1b934d";
const String TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500";
const String TMDB_TRAILER_BASE_URL = "https://api.themoviedb.org/3/movie/";

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

    // Genre ID'lerini, MovieManager'daki harita ile isimlere çeviriyoruz
    if (json['genre_ids'] is List) {
      for (var id in json['genre_ids']) {
        final genreName = manager._genreMap[id] ?? 'Unknown';
        genresList.add(genreName);
      }
      if (genresList.isEmpty) genresList.add("Unknown");
    } else {
      genresList.add("Unknown");
    }

    // Rating kontrolü
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
      poster: posterPath.isNotEmpty
          ? TMDB_IMAGE_BASE_URL + posterPath
          : 'https://via.placeholder.com/500x750',
      genres: genresList.take(2).toList(), // İlk 2 türü al
      plot: json['overview'] ?? 'No description available.',
      actors: ["Loading..."],
      trailerId: '',
    );
  }
}

class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();

  // YENİ HARİTA VE GETTER'LAR (CategoriesView ve GenreService için gerekli)
  Map<int, String> _genreMap = {};
  Map<int, String> get idToNameMap => _genreMap; // GenreService'e erişim için
  List<String> get allGenreNames =>
      _genreMap.values.toList(); // CategoriesView için

  MovieManager._privateConstructor();

  final List<Movie> _allMovies = [];
  final List<Movie> _trendingMovies = []; // Carousel için kullanıyoruz
  final List<Movie> _favoriteMovies = [];

  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMorePages = true;

  List<Movie> get allMovies => _allMovies;
  // Artık Trending Movies listesini sadece ilk sayfadan alıyoruz
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get favoriteMovies => _favoriteMovies;
  bool get isFetching => _isFetching;
  bool get hasMorePages => _hasMorePages;

  bool isFavorite(Movie movie) => _favoriteMovies.contains(movie);

  void toggleFavorite(Movie movie) {
    if (_favoriteMovies.contains(movie)) {
      _favoriteMovies.remove(movie);
    } else {
      _favoriteMovies.add(movie);
    }
    notifyListeners();
  }

  // --- 1. TÜM KATEGORİLERİ ÇEKME VE POSTER İSTEĞİNİ BAŞLATMA ---
  Future<void> fetchGenres() async {
    if (_genreMap.isNotEmpty) return; // Zaten yüklüyse tekrar çekme

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

          print(
            'TMDB BAŞARILI: Tür Eşleştirmesi Yüklendi. Boyut: ${_genreMap.length}',
          );

          // GenreService'e haritayı aktar
          GenreService.instance.setGenreMapping(_genreMap);

          // YENİ: Poster çekimini başlat
          _genreMap.forEach((id, name) {
            GenreService.instance.fetchGenrePosterUrl(name, id);
          });
        }
      }
    } catch (e) {
      print('TMDB Genre çekme hatası: $e');
    }
  }

  // --- 2. ANA LİSTEYİ VE TRENDİNG FİLMLERİ ÇEKME FONKSİYONU ---
  Future<void> fetchNextPageMovies({bool initial = false}) async {
    // Burada fetchGenres() çağrısı yok, çünkü bu çağrı main.dart'a taşındı.

    if (!initial && (_isFetching || !_hasMorePages)) return;

    _isFetching = true;

    if (initial) {
      _currentPage = 1;
      _allMovies.clear();
      _trendingMovies.clear(); // Trend listesini de temizle
      _hasMorePages = true;
    }

    // API anahtarı kontrolü
    if (TMDB_API_KEY.isEmpty) {
      print(
        'TMDB HATA: Lütfen API anahtarını movie_manager.dart dosyasına girin!',
      );
      _isFetching = false;
      notifyListeners();
      return;
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

        // İlk sayfa yükleniyorsa, ilk 5-10 filmi Trending listesine ekle
        if (initial) {
          // Örnek: İlk 10 filmi trending yap
          _trendingMovies.addAll(newMovies.take(10));
        }

        int totalPages = data['total_pages'] ?? 0;
        if (_currentPage >= totalPages) {
          _hasMorePages = false;
        } else {
          _currentPage++;
        }

        print(
          'TMDB: Sayfa $_currentPage yüklendi. Toplam film: ${_allMovies.length}',
        );
      } else {
        print('Failed to load movies from TMDB: ${response.statusCode}');
        _hasMorePages = false;
      }
    } catch (e) {
      print('TMDB connection error: $e');
      _hasMorePages = false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  // --- DETAY SAYFASI İÇİN: CAST BİLGİSİNİ ÇEKME ---
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

      if (castNames.isNotEmpty)
        movie.actors = castNames;
      else
        movie.actors = ["Cast Not Found"];

      notifyListeners();
    }
  }

  // --- DETAY SAYFASI İÇİN: FRAGMAN BİLGİSİNİ ÇEKME ---
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

      if (trailer != null) {
        movie.trailerId = trailer['key'];
      } else {
        movie.trailerId = 'dQw4w9WgXcQ';
      }

      notifyListeners();
    }
  }

  // --- DİĞER METOTLAR ---
  final Map<String, String> _actorPhotos = {
    // ... (Oyuncu fotoğraf listesi)
    "Timothée Chalamet":
        "https://image.tmdb.org/t/p/w500/BE2sdjpgEHr2WlOuto5xSVXH2S.jpg",
    "Zendaya": "https://image.tmdb.org/t/p/w500/cbCibOA1yQOgeqIVMlTPZjNdB4.jpg",
    // ... (Diğer tüm oyuncu listesi aynı kalmalı)
    "Ryan Reynolds":
        "https://image.tmdb.org/t/p/w500/2752kUofqaFv8dUc2vZ4Q2c0s1Q.jpg",
    "Hugh Jackman":
        "https://image.tmdb.org/t/p/w500/4Xujtewxrt5aWA5jIIqk89sccrM.jpg",
    "Cillian Murphy":
        "https://image.tmdb.org/t/p/w500/2l9G2b7mqj9W16aHj8z88X53W7a.jpg",
    "Emily Blunt":
        "https://image.tmdb.org/t/p/w500/nPJXaR7vXFq8kG0Qj1V6xJ6G7f.jpg",
    "Amy Poehler":
        "https://image.tmdb.org/t/p/w500/kS94v7jVj6Zg5X7q9q3z3j9x4r.jpg",
    "Maya Hawke":
        "https://image.tmdb.org/t/p/w500/xS1x8f9x8x8x8x8x8x8x8x8x8x8.jpg",
    "Kirsten Dunst":
        "https://image.tmdb.org/t/p/w500/6Le11J1851Z64m039545452202.jpg",
    "Wagner Moura":
        "https://image.tmdb.org/t/p/w500/a316223321515151515151515151.jpg",
    "Tim Robbins":
        "https://image.tmdb.org/t/p/w500/hsCu1JUzQQ4pl7uFxAVFLOs9yHh.jpg",
    "Morgan Freeman":
        "https://image.tmdb.org/t/p/w500/oIciQWr8VwKoR8TmAw1OWai2P5x.jpg",
    "Marlon Brando":
        "https://image.tmdb.org/t/p/w500/fuTEPMsBtV1zE98ujPONbKiYDc2.jpg",
    "Al Pacino":
        "https://image.tmdb.org/t/p/w500/fMDFeVf0pjopTJbyRSLFwNDm8Wr.jpg",
    "Christian Bale":
        "https://image.tmdb.org/t/p/w500/b7fTC9WFkgqGOv77mLQzsD24vti.jpg",
    "Heath Ledger":
        "https://image.tmdb.org/t/p/w500/5Y9Hn3wR9X4e7y7y7y7y7y7y7y7y.jpg",
    "Leonardo DiCaprio":
        "https://image.tmdb.org/t/p/w500/wo2hJpn04vbtmh0B9utCFdsQhxM.jpg",
    "Joseph Gordon-Levitt":
        "https://image.tmdb.org/t/p/w500/dhv9f3AaozOjpvjNrBe5538sj7.jpg",
    "Matthew McConaughey":
        "https://image.tmdb.org/t/p/w500/wJcz7dZ0J67575757575757575.jpg",
    "Anne Hathaway":
        "https://image.tmdb.org/t/p/w500/tLelKoPNiyJCSEtQTz1FGv4TLGc.jpg",
    "John Travolta":
        "https://image.tmdb.org/t/p/w500/sHnmW4k44jZ3Z2Z3Z3Z3Z3Z3Z3.jpg",
    "Uma Thurman":
        "https://image.tmdb.org/t/p/w500/f5d8zH5j5j5j5j5j5j5j5j5j5j.jpg",
    "Brad Pitt":
        "https://image.tmdb.org/t/p/w500/cckcYc2v0yh1tc9QjRelptcOBko.jpg",
    "Edward Norton":
        "https://image.tmdb.org/t/p/w500/5XBzD5WuTyVQZeS4VI25z2moMeY.jpg",
    "Tom Hanks":
        "https://image.tmdb.org/t/p/w500/xndWFsBlClOJFRdhSt4NBwiPq2o.jpg",
    "Robin Wright":
        "https://image.tmdb.org/t/p/w500/ro170566666666666666666666.jpg",
    "Keanu Reeves":
        "https://image.tmdb.org/t/p/w500/4D0PpNI0kmP58hgrwGC3WCikezn.jpg",
    "Laurence Fishburne":
        "https://image.tmdb.org/t/p/w500/8suOoWapX0MwzWn9vyVyXJj6J1x.jpg",
    "Elijah Wood":
        "https://image.tmdb.org/t/p/w500/7UKRbJBNG7mxZ73CZqZZdtqv8JB.jpg",
    "Viggo Mortensen":
        "https://image.tmdb.org/t/p/w500/vH5gVspNmzSBdccqZg3tU5yS9wJ.jpg",
    "Mark Hamill":
        "https://image.tmdb.org/t/p/w500/fk8OfdReNltKZqOk2TZgkofCUFq.jpg",
    "Harrison Ford":
        "https://image.tmdb.org/t/p/w500/5M7oN3sznp99hWYQ9sX0xheswWX.jpg",
    "Russell Crowe":
        "https://image.tmdb.org/t/p/w500/mGTtPuwE0y3XSVOEIj3UH5fCQlb.jpg",
    "Joaquin Phoenix":
        "https://image.tmdb.org/t/p/w500/nXMzvVF6xR3OXOedozfOcoA20xh.jpg",
    "Arnold Schwarzenegger":
        "https://image.tmdb.org/t/p/w500/zEMMy37f7X2C22F5f5f5f5f5f5f5.jpg",
    "Linda Hamilton":
        "https://image.tmdb.org/t/p/w500/fcR33333333333333333333333.jpg",
    "Michael J. Fox":
        "https://image.tmdb.org/t/p/w500/2jbAkS2Zl9sHk67W5r9U2Uf7o0o.jpg",
    "Christopher Lloyd":
        "https://image.tmdb.org/t/p/w500/iQg29f8g850J26Vf45Q1X87370Z.jpg",
    "Matthew Broderick":
        "https://image.tmdb.org/t/p/w500/pvQWsu0qcj02x4Wq0Z6yJ0x8082.jpg",
    "Jeremy Irons":
        "https://image.tmdb.org/t/p/w500/j6yD23B48657656865758675.jpg",
  };

  Map<String, String> getActorDetails(String actorName) {
    String bio =
        "$actorName is a world-renowned actor known for their versatility and charismatic screen presence. They have starred in numerous blockbuster films and received critical acclaim for their performances.";
    String cleanName = actorName.trim();
    String photo =
        _actorPhotos[cleanName] ??
        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(cleanName)}&background=0D8ABC&color=fff&size=512&bold=true";

    return {"bio": bio, "photo": photo};
  }
}
