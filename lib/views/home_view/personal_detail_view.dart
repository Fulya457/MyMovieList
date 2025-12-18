import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class PersonDetailView extends StatefulWidget {
  final Person person;
  const PersonDetailView({super.key, required this.person});

  @override
  State<PersonDetailView> createState() => _PersonDetailViewState();
}

class _PersonDetailViewState extends State<PersonDetailView> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _filteredMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    await MovieManager.instance.fetchPersonDetails(widget.person);
    if (mounted) {
      setState(() {
        _filteredMovies = widget.person.filmography;
        _isLoading = false;
      });
    }
  }

  void _filterMovies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMovies = widget.person.filmography;
      } else {
        _filteredMovies = widget.person.filmography
            .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Yaş Hesaplama
  String _getAge() {
    if (widget.person.birthday.isEmpty) return "";
    try {
      DateTime birth = DateTime.parse(widget.person.birthday);
      int age = DateTime.now().year - birth.year;
      return "$age yaşında";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: AnimatedBuilder(
        animation: MovieManager.instance,
        builder: (context, child) {
          bool isFav = MovieManager.instance.isPersonFavorite(widget.person);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: AppTheme.backgroundBlack,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
                    ),
                    onPressed: () => MovieManager.instance.togglePersonFavorite(
                      widget.person,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.person.profilePath.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.person.profilePath,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            )
                          : Container(color: Colors.grey),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.backgroundBlack,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.person.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${widget.person.knownFor} • ${_getAge()}",
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            if (widget.person.placeOfBirth.isNotEmpty)
                              Text(
                                widget.person.placeOfBirth,
                                style: const TextStyle(color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.person.biography.isNotEmpty) ...[
                        const Text(
                          "Biyografi",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.person.biography,
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // --- FİLMOGRAFİ ARAMA KUTUSU ---
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "${widget.person.name} filmlerinde ara...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primaryBlue,
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _filterMovies,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredMovies.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      "Film bulunamadı.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final movie = _filteredMovies[index];
                      return GestureDetector(
                        onTap: () =>
                            context.push('/movie-detail', extra: movie),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: movie.poster,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }, childCount: _filteredMovies.length),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
            ],
          );
        },
      ),
    );
  }
}
