// Dosya: lib/views/categories_view/categories_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/data/genre_service.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        GenreService.instance,
        MovieManager.instance,
      ]),
      builder: (context, child) {
        final allGenres = MovieManager.instance.allGenreNames;
        final isDark = MovieManager.instance.isDarkMode;

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          body: CustomScrollView(
            slivers: [
              // --- GRADIENT HEADER ---
              SliverAppBar(
                expandedHeight: 100,
                pinned: true,
                backgroundColor: AppTheme.backgroundBlack,
                // GERİ TUŞU EKLENDİ (Ana Sayfaya döner)
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
                  onPressed: () => context.go(AppRouters.home),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.deepPurpleAccent.withValues(
                            alpha: isDark ? 0.3 : 0.15,
                          ),
                          AppTheme.backgroundBlack,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'KATEGORİLER',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.deepPurpleAccent.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- İÇERİK (GRID) ---
              if (allGenres.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Kategori yüklenemedi.',
                      style: TextStyle(
                        color: AppTheme.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final genreName = allGenres[index];
                      final posterUrl =
                          GenreService.instance.genrePosterUrls[genreName];

                      Widget imageWidget = posterUrl != null
                          ? Image.network(
                              posterUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: AppTheme.surfaceDark,
                                    );
                                  },
                              errorBuilder: (c, o, s) =>
                                  Container(color: AppTheme.surfaceDark),
                            )
                          : Container(color: AppTheme.surfaceDark);

                      return GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            AppRouters.genreMovies,
                            pathParameters: {'genre': genreName},
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Opacity(opacity: 0.8, child: imageWidget),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.backgroundBlack.withValues(
                                        alpha: 0.9,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  genreName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: allGenres.length),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        );
      },
    );
  }
}
