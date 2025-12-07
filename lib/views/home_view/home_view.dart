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

    // --- FİLMLER VE FRAGMANLAR (AYNI VERİ) ---
    final List<Movie> mockMovies = [
       Movie(id: 1, title: "The Shawshank Redemption", rating: 9.3, poster: "https://m.media-amazon.com/images/M/MV5BMDFkYTc0MGEtZmNhMC00ZDIzLWFmNTEtODM1ZmRlYWMwMWFmXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_QL75_UX380_CR0,4,380,562_.jpg", genres: ["Drama"], plot: "Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.", actors: ["Tim Robbins", "Morgan Freeman"], trailerId: "PLl99DlL6b4"),
      Movie(id: 2, title: "The Godfather", rating: 9.2, poster: "https://m.media-amazon.com/images/M/MV5BM2MyNjYxNmUtYTAwNi00MTYxLWJmNWYtYzZlODY3ZTk3OTFlXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_QL75_UY562_CR8,0,380,562_.jpg", genres: ["Crime", "Drama"], plot: "The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.", actors: ["Marlon Brando", "Al Pacino"], trailerId: "UaVTIH8mujA"),
      Movie(id: 3, title: "The Dark Knight", rating: 9.0, poster: "https://m.media-amazon.com/images/M/MV5BMTMxNTMwODM0NF5BMl5BanBnXkFtZTcwODAyMTk2Mw@@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Action", "Crime"], plot: "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.", actors: ["Christian Bale", "Heath Ledger"], trailerId: "EXeTwQWrcwY"),
      Movie(id: 4, title: "Inception", rating: 8.8, poster: "https://m.media-amazon.com/images/M/MV5BMjAxMzY3NjcxNF5BMl5BanBnXkFtZTcwNTI5OTM0Mw@@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Sci-Fi", "Action"], plot: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.", actors: ["Leonardo DiCaprio", "Joseph Gordon-Levitt"], trailerId: "YoHD9XEInc0"),
      Movie(id: 5, title: "Interstellar", rating: 8.7, poster: "https://m.media-amazon.com/images/M/MV5BZjdkOTU3MDktN2IxOS00OGEyLWFmMjktY2FiMmZkNWIyODZiXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_QL75_UX380_CR0,0,380,562_.jpg", genres: ["Adventure", "Sci-Fi"], plot: "A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival.", actors: ["Matthew McConaughey", "Anne Hathaway"], trailerId: "zSWdZVtXT7E"),
      Movie(id: 6, title: "Pulp Fiction", rating: 8.9, poster: "https://m.media-amazon.com/images/M/MV5BNGNhMDIzZTUtNTBlZi00MTRlLWFjM2ItYzViMjE3YzI5MjljXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_QL75_UY562_CR1,0,380,562_.jpg", genres: ["Crime", "Drama"], plot: "The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.", actors: ["John Travolta", "Uma Thurman"], trailerId: "s7EdQ4FqbhY"),
      Movie(id: 7, title: "Fight Club", rating: 8.8, poster: "https://m.media-amazon.com/images/M/MV5BMmEzNTkxYjQtZTc0MC00YTVjLTg5ZTEtZWMwOWVlYzY0NWIwXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_QL75_UY562_CR1,0,380,562_.jpg", genres: ["Drama"], plot: "An insomniac office worker and a devil-may-care soapmaker form an underground fight club that evolves into much more.", actors: ["Brad Pitt", "Edward Norton"], trailerId: "qtRKdVHc-cE"),
      Movie(id: 8, title: "Forrest Gump", rating: 8.8, poster: "https://m.media-amazon.com/images/M/MV5BNWIwODRlZTUtY2U3ZS00Yzg1LWJhNzYtMmZiYmEyNmU1NjMzXkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_QL75_UY562_CR1,0,380,562_.jpg", genres: ["Drama", "Romance"], plot: "The presidencies of Kennedy and Johnson, the events of Vietnam, Watergate and other historical events unfold from the perspective of an Alabama man with an IQ of 75.", actors: ["Tom Hanks", "Robin Wright"], trailerId: "bLvqoHBptjg"),
      Movie(id: 9, title: "The Matrix", rating: 8.7, poster: "https://m.media-amazon.com/images/M/MV5BNzQzOTk3OTAtNDQ0Zi00ZTVkLWI0MTEtMDllZjNkYzNjNTc4L2ltYWdlXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR8,0,380,562_.jpg", genres: ["Action", "Sci-Fi"], plot: "A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.", actors: ["Keanu Reeves", "Laurence Fishburne"], trailerId: "vKQi3bBA1y8"),
      Movie(id: 10, title: "Lord of the Rings: Return of the King", rating: 9.0, poster: "https://m.media-amazon.com/images/M/MV5BNzA5ZDNlZKKtMTc2ZS00ZWJjLTg5MTEtZTk3NzM1ZTg0NGM5L2ltYWdlXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR8,0,380,562_.jpg", genres: ["Adventure", "Fantasy"], plot: "Gandalf and Aragorn lead the World of Men against Sauron's army to draw his gaze from Frodo and Sam as they approach Mount Doom with the One Ring.", actors: ["Elijah Wood", "Viggo Mortensen"], trailerId: "r5X-hFf6Bwo"),
      Movie(id: 11, title: "Star Wars: Empire Strikes Back", rating: 8.7, poster: "https://m.media-amazon.com/images/M/MV5BYmU1NDRjNDT1M2UwZC00ZmE5LTM3NzctN2MwN2OWQ0ZZTlZJkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_QL75_UX380_CR0,4,380,562_.jpg", genres: ["Action", "Adventure"], plot: "After the Rebels are brutally overpowered by the Empire on the ice planet Hoth, Luke Skywalker begins Jedi training with Yoda.", actors: ["Mark Hamill", "Harrison Ford"], trailerId: "JNwNXF9Y6kY"),
      Movie(id: 12, title: "Gladiator", rating: 8.5, poster: "https://m.media-amazon.com/images/M/MV5BMDliMmNhNDEtODUyOS00MjNlLTgxODEtN2U3NzIxMGVkZTA1L2ltYWdlXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Action", "Drama"], plot: "A former Roman General sets out to exact vengeance against the corrupt emperor who murdered his family and sent him into slavery.", actors: ["Russell Crowe", "Joaquin Phoenix"], trailerId: "P5ieIbInFpg"),
      Movie(id: 13, title: "The Lion King", rating: 8.5, poster: "https://m.media-amazon.com/images/M/MV5BYTYxNGMyZTYtMjE3MS00MzNjLWFjNmYtMDk3N2FmM2JiM2M1XkEyXkFqcGdeQXVyNjY5NDU4NzI@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Animation", "Drama"], plot: "Lion prince Simba and his father are targeted by his bitter uncle, who wants to ascend the throne himself.", actors: ["Matthew Broderick", "Jeremy Irons"], trailerId: "7TavVZMewpY"),
      Movie(id: 14, title: "Back to the Future", rating: 8.5, poster: "https://m.media-amazon.com/images/M/MV5BZmU0M2Y1OGUtZjIxNi00ZjBkLTg1MjgtOWIyNThiZWIwYjRiXkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Adventure", "Comedy"], plot: "Marty McFly, a 17-year-old high school student, is accidentally sent thirty years into the past in a time-traveling DeLorean invented by his close friend, the eccentric scientist Doc Brown.", actors: ["Michael J. Fox", "Christopher Lloyd"], trailerId: "qvsgGtivCgs"),
      Movie(id: 15, title: "Terminator 2", rating: 8.6, poster: "https://m.media-amazon.com/images/M/MV5BMGU2NzRmZjUtOGUxYS00ZjdjLWEwZWItY2NlM2JhNjkxNTFmXkEyXkFqcGdeQXVyNjU0OTQ0OTY@._V1_QL75_UY562_CR0,0,380,562_.jpg", genres: ["Action", "Sci-Fi"], plot: "A cyborg, identical to the one who failed to kill Sarah Connor, must now protect her ten-year-old son John from a more advanced and powerful cyborg.", actors: ["Arnold Schwarzenegger", "Linda Hamilton"], trailerId: "IwQiA-XjXU0"),
    ];

    MovieManager.instance.setMovies(mockMovies);

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MovieManager.instance,
      builder: (context, child) {
        final allMovies = MovieManager.instance.allMovies;
        final filteredMovies = allMovies.where((movie) {
          return movie.title.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // --- ARAMA KUTUSU (DARK MODE) ---
                  TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    style: const TextStyle(color: Colors.white), // Yazı rengi beyaz
                    cursorColor: AppTheme.primaryBlue,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C), // Koyu Gri Kutu
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                      hintText: 'Search movies...',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- FİLM LİSTESİ ---
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                        : filteredMovies.isEmpty
                            ? const Center(child: Text('No movies found.', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: filteredMovies.length,
                                itemBuilder: (context, index) {
                                  final movie = filteredMovies[index];
                                  final isFav = MovieManager.instance.isFavorite(movie);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    color: AppTheme.surfaceDark, // Koyu Kart Rengi
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
                                          tag: 'poster_${movie.id}',
                                          child :ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            movie.poster, width: 50, height: 75, fit: BoxFit.cover,
                                            errorBuilder: (c,o,s) => Container(width: 50, height: 75, color: Colors.grey[800], child: const Icon(Icons.movie, color: Colors.white)),
                                          ),
                                        ),
                                        ),
                                        title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                          '${movie.genres.first} • ⭐ ${movie.rating}', 
                                          style: TextStyle(color: AppTheme.primaryBlue.withOpacity(0.8), fontWeight: FontWeight.w500),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            color: isFav ? AppTheme.primaryBlue : Colors.grey,
                                          ),
                                          onPressed: () {
                                            MovieManager.instance.toggleFavorite(movie);
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}