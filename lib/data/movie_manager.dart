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
}

class MovieManager extends ChangeNotifier {
  static final MovieManager instance = MovieManager._privateConstructor();
  MovieManager._privateConstructor();

  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];
  final List<Movie> _favoriteMovies = [];

  List<Movie> get allMovies => _allMovies;
  List<Movie> get trendingMovies => _trendingMovies;
  List<Movie> get favoriteMovies => _favoriteMovies;

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

  // --- 1. OYUNCU FOTOĞRAFLARI (TMDB) ---
  final Map<String, String> _actorPhotos = {
    // Trendler
    "Timothée Chalamet":
        "https://image.tmdb.org/t/p/w500/BE2sdjpgEHr2WlOuto5xSVXH2S.jpg",
    "Zendaya": "https://image.tmdb.org/t/p/w500/cbCibOA1yQOgeqIVMlTPZjNdB4.jpg",
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
        "https://image.tmdb.org/t/p/w500/a316223321515151515151.jpg",

    // Klasikler
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
        "https://image.tmdb.org/t/p/w500/5Y9Hn3wR9X4e7y7y7y7y7y7y7y.jpg",
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
        "https://image.tmdb.org/t/p/w500/zEMMy37f7X2C22F5f5f5f5f5f5.jpg",
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

  // --- 2. FİLM VERİLERİNİ YÜKLEYEN FONKSİYON ---
  // (Artık HomeView'da değil, burada tanımlıyoruz)
  void initializeMovies() {
    if (_allMovies.isNotEmpty) return;

    final List<Movie> trends = [
      Movie(
        id: 101,
        title: "Dune: Part Two",
        rating: 8.8,
        poster:
            "https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg",
        genres: ["Sci-Fi", "Adventure"],
        plot:
            "Paul Atreides unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.",
        actors: ["Timothée Chalamet", "Zendaya"],
        trailerId: "Way9Dexny3w",
      ),
      Movie(
        id: 102,
        title: "Deadpool & Wolverine",
        rating: 8.2,
        poster:
            "https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg",
        genres: ["Action", "Comedy"],
        plot:
            "Wolverine is recovering from his injuries when he crosses paths with the loudmouth, Deadpool.",
        actors: ["Ryan Reynolds", "Hugh Jackman"],
        trailerId: "73_1biulkYk",
      ),
      Movie(
        id: 103,
        title: "Oppenheimer",
        rating: 8.4,
        poster:
            "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg",
        genres: ["Biography", "Drama"],
        plot:
            "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.",
        actors: ["Cillian Murphy", "Emily Blunt"],
        trailerId: "uYPbbksJxIg",
      ),
      Movie(
        id: 104,
        title: "Inside Out 2",
        rating: 7.9,
        poster:
            "https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg",
        genres: ["Animation", "Family"],
        plot:
            "Joy, Sadness, Anger, Fear and Disgust have been running a successful operation by all accounts.",
        actors: ["Amy Poehler", "Maya Hawke"],
        trailerId: "LEjhY15eCx0",
      ),
      Movie(
        id: 105,
        title: "Civil War",
        rating: 7.4,
        poster:
            "https://image.tmdb.org/t/p/w500/sh7Rg8Er3tFcN9BpKIPOMvALgZd.jpg",
        genres: ["Action", "Thriller"],
        plot:
            "A journey across a dystopian future America, following a team of military-embedded journalists.",
        actors: ["Kirsten Dunst", "Wagner Moura"],
        trailerId: "aDyQxtg0V2w",
      ),
    ];

    final List<Movie> classics = [
      Movie(
        id: 1,
        title: "The Shawshank Redemption",
        rating: 9.3,
        poster:
            "https://image.tmdb.org/t/p/w500/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg",
        genres: ["Drama"],
        plot: "Two imprisoned men bond over a number of years...",
        actors: ["Tim Robbins", "Morgan Freeman"],
        trailerId: "PLl99DlL6b4",
      ),
      Movie(
        id: 2,
        title: "The Godfather",
        rating: 9.2,
        poster:
            "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
        genres: ["Crime", "Drama"],
        plot:
            "The aging patriarch of an organized crime dynasty transfers control...",
        actors: ["Marlon Brando", "Al Pacino"],
        trailerId: "UaVTIH8mujA",
      ),
      Movie(
        id: 3,
        title: "The Dark Knight",
        rating: 9.0,
        poster:
            "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
        genres: ["Action", "Crime"],
        plot: "When the menace known as the Joker wreaks havoc...",
        actors: ["Christian Bale", "Heath Ledger"],
        trailerId: "EXeTwQWrcwY",
      ),
      Movie(
        id: 4,
        title: "Inception",
        rating: 8.8,
        poster:
            "https://image.tmdb.org/t/p/w500/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
        genres: ["Sci-Fi", "Action"],
        plot: "A thief who steals corporate secrets through dream-sharing...",
        actors: ["Leonardo DiCaprio", "Joseph Gordon-Levitt"],
        trailerId: "YoHD9XEInc0",
      ),
      Movie(
        id: 5,
        title: "Interstellar",
        rating: 8.7,
        poster:
            "https://image.tmdb.org/t/p/w500/gEU2QniL6E8AHtMY4kO3MIhel72.jpg",
        genres: ["Adventure", "Sci-Fi"],
        plot: "A team of explorers travel through a wormhole in space...",
        actors: ["Matthew McConaughey", "Anne Hathaway"],
        trailerId: "zSWdZVtXT7E",
      ),
      Movie(
        id: 6,
        title: "Pulp Fiction",
        rating: 8.9,
        poster:
            "https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",
        genres: ["Crime", "Drama"],
        plot:
            "The lives of two mob hitmen, a boxer, a gangster and his wife...",
        actors: ["John Travolta", "Uma Thurman"],
        trailerId: "s7EdQ4FqbhY",
      ),
      Movie(
        id: 7,
        title: "Fight Club",
        rating: 8.8,
        poster:
            "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
        genres: ["Drama"],
        plot: "An insomniac office worker and a devil-may-care soapmaker...",
        actors: ["Brad Pitt", "Edward Norton"],
        trailerId: "qtRKdVHc-cE",
      ),
      Movie(
        id: 8,
        title: "Forrest Gump",
        rating: 8.8,
        poster:
            "https://image.tmdb.org/t/p/w500/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg",
        genres: ["Drama", "Romance"],
        plot:
            "The presidencies of Kennedy and Johnson, the events of Vietnam...",
        actors: ["Tom Hanks", "Robin Wright"],
        trailerId: "bLvqoHBptjg",
      ),
      Movie(
        id: 9,
        title: "The Matrix",
        rating: 8.7,
        poster:
            "https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
        genres: ["Action", "Sci-Fi"],
        plot: "A computer hacker learns from mysterious rebels...",
        actors: ["Keanu Reeves", "Laurence Fishburne"],
        trailerId: "vKQi3bBA1y8",
      ),
      Movie(
        id: 10,
        title: "Lord of the Rings: ROTK",
        rating: 9.0,
        poster:
            "https://image.tmdb.org/t/p/w500/rCzpDGLbOoPwLjy3OAm5NUPOTrC.jpg",
        genres: ["Adventure", "Fantasy"],
        plot: "Gandalf and Aragorn lead the World of Men...",
        actors: ["Elijah Wood", "Viggo Mortensen"],
        trailerId: "r5X-hFf6Bwo",
      ),
      Movie(
        id: 11,
        title: "Star Wars: Empire Strikes Back",
        rating: 8.7,
        poster:
            "https://image.tmdb.org/t/p/w500/20F670LS2q28gbd8nyq6G89AMEL.jpg",
        genres: ["Action", "Adventure"],
        plot: "After the Rebels are brutally overpowered by the Empire...",
        actors: ["Mark Hamill", "Harrison Ford"],
        trailerId: "JNwNXF9Y6kY",
      ),
      Movie(
        id: 12,
        title: "Gladiator",
        rating: 8.5,
        poster:
            "https://image.tmdb.org/t/p/w500/ty8TGRuvJLPUmAR1H1nRIsgwvim.jpg",
        genres: ["Action", "Drama"],
        plot: "A former Roman General sets out to exact vengeance...",
        actors: ["Russell Crowe", "Joaquin Phoenix"],
        trailerId: "P5ieIbInFpg",
      ),
      Movie(
        id: 13,
        title: "The Lion King",
        rating: 8.5,
        poster:
            "https://image.tmdb.org/t/p/w500/sKCr78MX80vByHill2l7plb1bjd.jpg",
        genres: ["Animation", "Drama"],
        plot:
            "Lion prince Simba and his father are targeted by his bitter uncle...",
        actors: ["Matthew Broderick", "Jeremy Irons"],
        trailerId: "7TavVZMewpY",
      ),
      Movie(
        id: 14,
        title: "Back to the Future",
        rating: 8.5,
        poster:
            "https://image.tmdb.org/t/p/w500/fNOH9f1aA7XRTzl1sA1xaU0nTAL.jpg",
        genres: ["Adventure", "Comedy"],
        plot: "Marty McFly, a 17-year-old high school student...",
        actors: ["Michael J. Fox", "Christopher Lloyd"],
        trailerId: "qvsgGtivCgs",
      ),
      Movie(
        id: 15,
        title: "Terminator 2",
        rating: 8.6,
        poster:
            "https://image.tmdb.org/t/p/w500/vqo3953M9W8x0q3F3RY4R6f05k6.jpg",
        genres: ["Action", "Sci-Fi"],
        plot:
            "A cyborg, identical to the one who failed to kill Sarah Connor...",
        actors: ["Arnold Schwarzenegger", "Linda Hamilton"],
        trailerId: "IwQiA-XjXU0",
      ),
    ];

    _trendingMovies = trends;
    _allMovies = [...trends, ...classics];
    notifyListeners();
  }

  Map<String, String> getActorDetails(String actorName) {
    String bio =
        "$actorName is a world-renowned actor known for their versatility and charismatic screen presence. They have starred in numerous blockbuster films and received critical acclaim for their performances.";

    // İsmi eşleştirirken boşluk hatası varsa düzelt (Trim)
    String cleanName = actorName.trim();

    String photo =
        _actorPhotos[cleanName] ??
        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(cleanName)}&background=0D8ABC&color=fff&size=512&bold=true";

    return {"bio": bio, "photo": photo};
  }
}
