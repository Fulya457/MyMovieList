import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/app/theme.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String searchQuery = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (MovieManager.instance.allMovies.isNotEmpty) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // --- 1. TRENDLER (YENİ FİLMLER) ---
    final List<Movie> trends = [
      Movie(id: 101, title: "Dune: Part Two", rating: 8.8, poster: "https://m.media-amazon.com/images/M/MV5BN2QyZGU4ZDctOWMzMy00NTc5LThlOGQtODhmNDI1NmY5YzAwXkEyXkFqcGdeQXVyMDM2NDM2MQ@@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Sci-Fi", "Adventure"], plot: "Paul Atreides unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.", actors: ["Timothée Chalamet", "Zendaya"], trailerId: "Way9Dexny3w"),
      Movie(id: 102, title: "Deadpool & Wolverine", rating: 8.2, poster: "https://m.media-amazon.com/images/M/MV5BZTEyZTZkMDctYzYzZS00MzU2LThhZjEtMmY4ZDQzY2FkYTEyXkEyXkFqcGc@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Action", "Comedy"], plot: "Wolverine is recovering from his injuries when he crosses paths with the loudmouth, Deadpool.", actors: ["Ryan Reynolds", "Hugh Jackman"], trailerId: "73_1biulkYk"),
      Movie(id: 103, title: "Oppenheimer", rating: 8.4, poster: "https://m.media-amazon.com/images/M/MV5BMDBmYTZjNjUtN2M1MS00MTQ2LTk2ODgtNzc2M2QyZGE5NTVjXkEyXkFqcGdeQXVyNzAwMjU2MTY@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Biography", "Drama"], plot: "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.", actors: ["Cillian Murphy", "Emily Blunt"], trailerId: "uYPbbksJxIg"),
      Movie(id: 104, title: "Inside Out 2", rating: 7.9, poster: "https://m.media-amazon.com/images/M/MV5BYTc1MDQ3NjAtOWEzMi00YzE1LWI2OWUtNjQ0OWJkMzI3MDhmXkEyXkFqcGdeQXVyMDM2NDM2MQ@@._V1_QL75_UY562_CR1,0,380,562_.jpg", genres: ["Animation", "Family"], plot: "Joy, Sadness, Anger, Fear and Disgust have been running a successful operation by all accounts.", actors: ["Amy Poehler", "Maya Hawke"], trailerId: "LEjhY15eCx0"),
      Movie(id: 105, title: "Civil War", rating: 7.4, poster: "https://m.media-amazon.com/images/M/MV5TYzk3M2Y3ZTMtMzljMC00MzM4LWJiOWItMzRiNmMzYzQ4MzMwXkEyXkFqcGdeQXVyMTUzMTg2ODkz._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Action", "Thriller"], plot: "A journey across a dystopian future America, following a team of military-embedded journalists.", actors: ["Kirsten Dunst", "Wagner Moura"], trailerId: "aDyQxtg0V2w"),
    ];

    // --- 2. KLASİKLER (15 FİLM) ---
    final List<Movie> classics = [
      Movie(id: 1, title: "The Shawshank Redemption", rating: 9.3, poster: "https://m.media-amazon.com/images/M/MV5BMDFkYTc0MGEtZmNhMC00ZDIzLWFmNTEtODM1ZmRlYWMwMWFmXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_QL75_UX380_CR0,4,380,562_.jpg", genres: ["Drama"], plot: "Two imprisoned men bond over a number of years...", actors: ["Tim Robbins", "Morgan Freeman"], trailerId: "PLl99DlL6b4"),
      Movie(id: 2, title: "The Godfather", rating: 9.2, poster: "https://m.media-amazon.com/images/M/MV5BM2MyNjYxNmUtYTAwNi00MTYxLWJmNWYtYzZlODY3ZTk3OTFlXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_QL75_UY562_CR8,0,380,562_.jpg", genres: ["Crime", "Drama"], plot: "The aging patriarch of an organized crime dynasty transfers control...", actors: ["Marlon Brando", "Al Pacino"], trailerId: "UaVTIH8mujA"),
      Movie(id: 3, title: "The Dark Knight", rating: 9.0, poster: "https://m.media-amazon.com/images/M/MV5BMTMxNTMwODM0NF5BMl5BanBnXkFtZTcwODAyMTk2Mw@@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Action", "Crime"], plot: "When the menace known as the Joker wreaks havoc...", actors: ["Christian Bale", "Heath Ledger"], trailerId: "EXeTwQWrcwY"),
      Movie(id: 4, title: "Inception", rating: 8.8, poster: "https://m.media-amazon.com/images/M/MV5BMjAxMzY3NjcxNF5BMl5BanBnXkFtZTcwNTI5OTM0Mw@@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Sci-Fi", "Action"], plot: "A thief who steals corporate secrets through dream-sharing...", actors: ["Leonardo DiCaprio", "Joseph Gordon-Levitt"], trailerId: "YoHD9XEInc0"),
      Movie(id: 5, title: "Interstellar", rating: 8.7, poster: "https://m.media-amazon.com/images/M/MV5BZjdkOTU3MDktN2IxOS00OGEyLWFmMjktY2FiMmZkNWIyODZiXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Adventure", "Sci-Fi"], plot: "A team of explorers travel through a wormhole in space...", actors: ["Matthew McConaughey", "Anne Hathaway"], trailerId: "zSWdZVtXT7E"),
      Movie(id: 6, title: "Pulp Fiction", rating: 8.9, poster: "https://m.media-amazon.com/images/M/MV5BNGNhMDIzZTUtNTBlZi00MTRlLWFjM2ItYzViMjE3YzI5MjljXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_QL75_UY562_CR1,0,380,562_.jpg", genres: ["Crime", "Drama"], plot: "The lives of two mob hitmen, a boxer, a gangster and his wife...", actors: ["John Travolta", "Uma Thurman"], trailerId: "s7EdQ4FqbhY"),
      Movie(id: 7, title: "Fight Club", rating: 8.8, poster: "https://m.media-amazon.com/images/M/MV5BMmEzNTkxYjQtZTc0MC00YTVjLTg5ZTEtZWMwOWVlYzY0NWIwXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_QL75_UY562_CR1,0,380,562_.jpg", genres: ["Drama"], plot: "An insomniac office worker and a devil-may-care soapmaker...", actors: ["Brad Pitt", "Edward Norton"], trailerId: "qtRKdVHc-cE"),
      Movie(id: 8, title: "Forrest Gump", rating: 8.8, poster: "https://m.media-amazon.com/images/M/MV5BNWIwODRlZTUtY2U3ZS00Yzg1LWJhNzYtMmZiYmEyNmU1NjMzXkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_QL75_UY562_CR1,0,380,562_.jpg", genres: ["Drama", "Romance"], plot: "The presidencies of Kennedy and Johnson, the events of Vietnam...", actors: ["Tom Hanks", "Robin Wright"], trailerId: "bLvqoHBptjg"),
      Movie(id: 9, title: "The Matrix", rating: 8.7, poster: "https://m.media-amazon.com/images/M/MV5BNzQzOTk3OTAtNDQ0Zi00ZTVkLWI0MTEtMDllZjNkYzNjNTc4L2ltYWdlXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR8,0,380,562_.jpg", genres: ["Action", "Sci-Fi"], plot: "A computer hacker learns from mysterious rebels...", actors: ["Keanu Reeves", "Laurence Fishburne"], trailerId: "vKQi3bBA1y8"),
      Movie(id: 10, title: "Lord of the Rings: Return of the King", rating: 9.0, poster: "https://m.media-amazon.com/images/M/MV5BNzA5ZDNlZKKtMTc2ZS00ZWJjLTg5MTEtZTk3NzM1ZTg0NGM5L2ltYWdlXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR8,0,380,562_.jpg", genres: ["Adventure", "Fantasy"], plot: "Gandalf and Aragorn lead the World of Men against Sauron's army...", actors: ["Elijah Wood", "Viggo Mortensen"], trailerId: "r5X-hFf6Bwo"),
      Movie(id: 11, title: "Star Wars: Empire Strikes Back", rating: 8.7, poster: "https://m.media-amazon.com/images/M/MV5BYmU1NDRjNDT1M2UwZC00ZmE5LTM3NzctN2MwN2OWQ0ZZTlZJkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_QL75_UX380_CR0,4,380,562_.jpg", genres: ["Action", "Adventure"], plot: "After the Rebels are brutally overpowered by the Empire...", actors: ["Mark Hamill", "Harrison Ford"], trailerId: "JNwNXF9Y6kY"),
      Movie(id: 12, title: "Gladiator", rating: 8.5, poster: "https://m.media-amazon.com/images/M/MV5BMDliMmNhNDEtODUyOS00MjNlLTgxODEtN2U3NzIxMGVkZTA1L2ltYWdlXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Action", "Drama"], plot: "A former Roman General sets out to exact vengeance...", actors: ["Russell Crowe", "Joaquin Phoenix"], trailerId: "P5ieIbInFpg"),
      Movie(id: 13, title: "The Lion King", rating: 8.5, poster: "https://m.media-amazon.com/images/M/MV5BYTYxNGMyZTYtMjE3MS00MzNjLWFjNmYtMDk3N2FmM2JiM2M1XkEyXkFqcGdeQXVyNjY5NDU4NzI@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Animation", "Drama"], plot: "Lion prince Simba and his father are targeted by his bitter uncle...", actors: ["Matthew Broderick", "Jeremy Irons"], trailerId: "7TavVZMewpY"),
      Movie(id: 14, title: "Back to the Future", rating: 8.5, poster: "https://m.media-amazon.com/images/M/MV5BZmU0M2Y1OGUtZjIxNi00ZjBkLTg1MjgtOWIyNThiZWIwYjRiXkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Adventure", "Comedy"], plot: "Marty McFly, a 17-year-old high school student...", actors: ["Michael J. Fox", "Christopher Lloyd"], trailerId: "qvsgGtivCgs"),
      Movie(id: 15, title: "Terminator 2", rating: 8.6, poster: "https://m.media-amazon.com/images/M/MV5BMGU2NzRmZjUtOGUxYS00ZjdjLWEwZWItY2NlM2JhNjkxNTFmXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Action", "Sci-Fi"], plot: "A cyborg, identical to the one who failed to kill Sarah Connor...", actors: ["Arnold Schwarzenegger", "Linda Hamilton"], trailerId: "IwQiA-XjXU0"),
    ];

    // --- ÖNEMLİ: HEPSİNİ BİRLEŞTİR ---
    // Böylece arama yapınca hem trendler hem klasikler çıkar
    final List<Movie> allCombined = [...trends, ...classics];

    MovieManager.instance.setTrendingMovies(trends); // Slider için sadece trendler
    MovieManager.instance.setMovies(allCombined);    // Liste ve Arama için HEPSİ

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        final allMovies = MovieManager.instance.allMovies;
        final trendingMovies = MovieManager.instance.trendingMovies;
        
        // FİLTRELEME (Artık hem trendler hem klasikler içinde arar)
        final filteredMovies = allMovies.where((movie) {
          return movie.title.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      // --- ARAMA KUTUSU ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (value) => setState(() => searchQuery = value),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: AppTheme.primaryBlue,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                            hintText: 'Search movies...',
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // --- EĞER ARAMA YAPILMIYORSA TRENDLERİ GÖSTER ---
                      if (!isLoading && searchQuery.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text("TRENDING NOW", style: TextStyle(color: AppTheme.primaryBlue, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              SizedBox(width: 8),
                              Icon(Icons.whatshot, color: Colors.orange, size: 20)
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),

                        // --- CAROUSEL SLIDER ---
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 250.0,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                            enlargeCenterPage: true,
                            aspectRatio: 16/9,
                            viewportFraction: 0.55,
                          ),
                          items: trendingMovies.map((movie) {
                            return Builder(
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  onTap: () {
                                     Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => MovieDetailView(movie: movie)),
                                      );
                                  },
                                  child: Hero(
                                    tag: 'poster_${movie.id}', // Tag unique olmalı
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(movie.poster, fit: BoxFit.cover),
                                            Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Colors.transparent, Colors.black87],
                                                  stops: [0.6, 1.0],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 10,
                                              left: 10,
                                              right: 10,
                                              child: Text(
                                                movie.title,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("ALL MOVIES", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // --- FİLM LİSTESİ (HEM TRENDLER HEM KLASİKLER) ---
                      if (isLoading)
                        const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                      else if (filteredMovies.isEmpty)
                        const Center(child: Text('No movies found.', style: TextStyle(color: Colors.grey)))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredMovies.length,
                          itemBuilder: (context, index) {
                            final movie = filteredMovies[index];
                            final isFav = MovieManager.instance.isFavorite(movie);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: AppTheme.surfaceDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => MovieDetailView(movie: movie)),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(8),
                                    leading: Hero(
                                      tag: 'list_poster_${movie.id}', // Slider ile çakışmaması için farklı tag
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          movie.poster, width: 50, height: 75, fit: BoxFit.cover,
                                          errorBuilder: (c,o,s) => Container(width: 50, height: 75, color: Colors.grey[800]),
                                        ),
                                      ),
                                    ),
                                    title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text('${movie.genres.first} • ⭐ ${movie.rating}', style: TextStyle(color: AppTheme.primaryBlue.withOpacity(0.8))),
                                    trailing: IconButton(
                                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppTheme.primaryBlue : Colors.grey),
                                      onPressed: () => MovieManager.instance.toggleFavorite(movie),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}