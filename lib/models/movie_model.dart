// Dosya: lib/models/movie_model.dart

const String TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500";

class Movie {
  final int id;
  final String title;
  final double rating;
  final String poster;
  final List<String> genres;
  final List<int> genreIds;
  final String plot;
  List<String> actors;
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
    required this.genreIds,
    required this.plot,
    this.actors = const ["Loading..."],
    this.castDetails = const [],
    this.director = "Unknown",
    this.trailerId = '',
    this.appRating,
    this.appVoteCount = 0,
    this.popularity = 0.0,
    this.releaseDate = "Unknown Date",
  });

  factory Movie.fromTMDB(
    Map<String, dynamic> json, [
    Map<int, String>? genreMap,
  ]) {
    String posterPath = json['poster_path'] ?? '';
    List<String> genresList = [];
    List<int> gIds = [];

    final mapToUse = genreMap ?? {};

    if (json['genre_ids'] is List) {
      for (var id in json['genre_ids']) {
        gIds.add(id as int);

        genresList.add(mapToUse[id] ?? 'Unknown');
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
      genreIds: gIds,
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
      genreIds: [],
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
