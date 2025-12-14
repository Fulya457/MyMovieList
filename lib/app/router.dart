import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/views/app_view.dart';
import 'package:mymovielist/views/favorites_view/favorites_view.dart';
import 'package:mymovielist/views/home_view/home_view.dart';
import 'package:mymovielist/views/recommended_view/recommended_view.dart';
import 'package:mymovielist/views/list_view/list_view.dart';
import 'package:mymovielist/views/login_view/login_view.dart';
import 'package:mymovielist/views/categories_view/categories_view.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/data/movie_manager.dart';

final _rooterKey = GlobalKey<NavigatorState>();

class AppRouters {
  static const String login = '/login';
  static const String home = '/';
  static const String favorites = '/favorites';
  static const String list = '/list'; // Categories View rotası
  static const String recommends = '/recommends';
  static const String genreMovies = 'genre-movies';
}

final router = GoRouter(
  navigatorKey: _rooterKey,
  initialLocation: AppRouters.login,
  routes: [
    // --- LOGIN ROUTE ---
    GoRoute(
      path: AppRouters.login,
      builder: (context, state) => const LoginView(),
    ),

    // --- SHELL DIŞI ROTLAR (Geri Butonu Gerekenler) ---

    // KATEGORİ FİLM LİSTESİ (GenreMoviesView)
    GoRoute(
      path: '${AppRouters.list}/:genre',
      name: AppRouters.genreMovies,
      builder: (context, state) {
        final genreName = state.pathParameters['genre']!;
        return GenreMoviesView(genre: genreName);
      },
    ),

    // FİLM DETAY SAYFASI (MovieDetailView)
    GoRoute(
      path: '/movie-detail',
      builder: (context, state) {
        final movie = state.extra;
        return MovieDetailView(movie: movie as Movie);
      },
    ),

    // --- ANA UYGULAMA (BOTTOM NAVIGATION BAR) ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppView(navigationShell: navigationShell),
      branches: [
        // BRANCH 1: HOME (Index 0)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouters.home,
              builder: (context, state) => const HomeView(),
            ),
          ],
        ),

        // BRANCH 2: KATEGORİ SEÇİM EKRANI (/list) (Index 1)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouters.list, // Parametresiz /list rotası
              builder: (context, state) => const CategoriesView(),
            ),
          ],
        ),

        // BRANCH 3: FAVORİLER (Index 2)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouters.favorites,
              builder: (context, state) => const FavoritesView(),
            ),
          ],
        ),

        // BRANCH 4: ÖNERİLER (RecommendedView Shell içine geri alındı) (Index 3)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouters.recommends,
              builder: (context, state) => const RecommendedView(),
            ),
          ],
        ),
      ],
    ),
  ],
);
