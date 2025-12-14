import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'movie_manager.dart'; // Movie sınıfına erişmek için
// manager. öneki ile global değişkenlere erişimi sağlayan import
import 'package:mymovielist/data/movie_manager.dart' as manager;

// KRİTİK DÜZELTME: manager. öneki ile global sabitlere doğru erişim
const String TMDB_API_KEY = manager.TMDB_API_KEY;
const String TMDB_IMAGE_BASE_URL =
    manager.TMDB_IMAGE_BASE_URL; // <-- Düzeltilmiş erişim

class GenreService extends ChangeNotifier {
  static final GenreService instance = GenreService._privateConstructor();
  GenreService._privateConstructor();

  final Map<String, GenreState> _genreStates = {};
  Map<String, int> _genreNameToId = {};

  // Yeni: Her kategori adı için poster URL'sini tutacak harita
  final Map<String, String> _genrePosterUrls = {};
  Map<String, String> get genrePosterUrls => _genrePosterUrls; // Getter

  GenreState getGenreState(String genreName) {
    if (!_genreStates.containsKey(genreName)) {
      _genreStates[genreName] = GenreState();
    }
    return _genreStates[genreName]!;
  }

  void setGenreMapping(Map<int, String> idToNameMap) {
    _genreNameToId = idToNameMap.map((id, name) => MapEntry(name, id));
    print(
      'GenreService: ${idToNameMap.length} adet tür ID/İsim eşleşmesi yüklendi.',
    );
  }

  // Yeni Metot: Kategoriye ait en popüler filmin posterini çekme
  Future<void> fetchGenrePosterUrl(String genreName, int genreId) async {
    // Eğer poster zaten çekilmişse veya ID 0 ise tekrar çekme
    if (_genrePosterUrls.containsKey(genreName) || genreId == 0) return;

    final url = Uri.parse(
      'https://api.themoviedb.org/3/discover/movie?api_key=$TMDB_API_KEY&with_genres=$genreId&sort_by=popularity.desc&page=1',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final posterPath = results.first['poster_path'];
          if (posterPath != null) {
            // KRİTİK DÜZELTME: MovieManager.TMDB_IMAGE_BASE_URL yerine
            // doğru global sabiti kullanıyoruz
            final fullUrl = TMDB_IMAGE_BASE_URL + posterPath;
            _genrePosterUrls[genreName] = fullUrl;
            // Poster yüklendiğinde CategoriesView'i güncellemek için notifyListeners ekliyoruz
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Genre poster fetch error for $genreName: $e');
    }
  }

  // --- FİLM ÇEKME FONKSİYONU (Hata Kontrollü) ---
  Future<void> fetchNextPageGenreMovies(
    String genreName, {
    bool initial = false,
  }) async {
    final state = getGenreState(genreName);
    final genreId = _genreNameToId[genreName];
    final String apiKey = TMDB_API_KEY;

    // KRİTİK ID VE API KEY KONTROLÜ
    if (genreId == null ||
        genreId == 0 ||
        apiKey.isEmpty ||
        apiKey.contains("YAPIŞTIR")) {
      print(
        'GENRE SERVİS HATA: Tür ID\'si bulunamadı veya API Key eksik. Adı: $genreName',
      );
      state.hasMorePages = false;
      state.isFetching = false;
      notifyListeners();
      return;
    }

    if (state.isFetching || !state.hasMorePages) return;

    state.isFetching = true;
    notifyListeners();

    if (initial) {
      state.currentPage = 1;
      state.movies.clear();
      state.hasMorePages = true;
    }

    final url = Uri.parse(
      'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=$genreId&page=${state.currentPage}',
    );

    print(
      'GENRE SERVİS ÇAĞRISI: $genreName için Sayfa ${state.currentPage} çekiliyor. ID: $genreId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Movie> newMovies = (data['results'] as List)
            .map((json) => Movie.fromTMDB(json))
            .toList();

        state.movies.addAll(newMovies);

        int totalPages = data['total_pages'] ?? 0;
        if (state.currentPage >= totalPages || newMovies.isEmpty) {
          state.hasMorePages = false;
        } else {
          state.currentPage++;
        }
        print(
          'GENRE SERVİS BAŞARILI: $genreName için ${newMovies.length} film yüklendi. Toplam: ${state.movies.length}',
        );
      } else {
        print('TMDB Genre Fetch Failed: ${response.statusCode}. URL: $url');
        state.hasMorePages = false;
      }
    } catch (e) {
      print('Genre connection error: $e');
      state.hasMorePages = false;
    } finally {
      state.isFetching = false;
      notifyListeners();
    }
  }
}

// Kategori yükleme durumunu tutan model
class GenreState {
  List<Movie> movies = [];
  int currentPage = 1;
  bool isFetching = false;
  bool hasMorePages = true;

  GenreState();
}
