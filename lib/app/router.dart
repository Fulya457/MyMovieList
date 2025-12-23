import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/views/app_view.dart';
import 'package:mymovielist/views/favorites_view/favorites_view.dart';
import 'package:mymovielist/views/home_view/home_view.dart';
import 'package:mymovielist/views/recommended_view/recommended_view.dart';
import 'package:mymovielist/views/categories_view/genre_movies_view.dart';
import 'package:mymovielist/views/login_view/login_view.dart';
import 'package:mymovielist/views/categories_view/categories_view.dart';
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/data/movie_manager.dart';
import 'package:mymovielist/views/login_view/welcome_screen.dart';
import 'package:mymovielist/views/profile_view/profile_view.dart';
import 'package:mymovielist/views/profile_view/notifications_view.dart';
import 'package:mymovielist/views/profile_view/user_reviews_view.dart';
import 'package:mymovielist/views/profile_view/friends_view.dart';
import 'package:mymovielist/views/profile_view/chat_view.dart';
import 'package:mymovielist/views/home_view/personal_detail_view.dart';
// YENİ IMPORT
import 'package:mymovielist/views/profile_view/user_lists_view.dart';

final _rooterKey = GlobalKey<NavigatorState>();

class AppRouters {
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String userReviews = '/user-reviews';
  static const String friends = '/friends';
  static const String chat = '/chat';
  
  // YENİ ROTA
  static const String userLists = '/user-lists';

  static const String home = '/';
  static const String favorites = '/favorites';
  static const String list = '/list';
  static const String recommends = '/recommends';
  static const String genreMovies = 'genre-movies';
}

final router = GoRouter(
  navigatorKey: _rooterKey,
  initialLocation: AppRouters.login,
  routes: [
    GoRoute(
      path: AppRouters.login,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: AppRouters.welcome,
      builder: (context, state) {
        final userName = state.extra as String;
        return WelcomeScreen(userName: userName);
      },
    ),
    GoRoute(
      path: '/person-detail',
      builder: (context, state) =>
          PersonDetailView(person: state.extra as Person),
    ),

    // --- PROFİL VE SOSYAL ---
    GoRoute(
      path: AppRouters.profile,
      builder: (context, state) => const ProfileView(),
    ),
    GoRoute(
      path: AppRouters.notifications,
      builder: (context, state) => const NotificationsView(),
    ),
    GoRoute(
      path: AppRouters.userReviews,
      builder: (context, state) => const UserReviewsView(),
    ),
    GoRoute(
      path: AppRouters.friends,
      builder: (context, state) => const FriendsView(),
    ),
    // YENİ EKLENEN ROTA TANIMI
    GoRoute(
      path: AppRouters.userLists,
      builder: (context, state) => const UserListsView(),
    ),

    GoRoute(
      path: AppRouters.chat,
      builder: (context, state) {
        final map = state.extra as Map<String, dynamic>;
        return ChatView(extras: map);
      },
    ),

    // --- DETAY VE LİSTELER ---
    GoRoute(
      path: '${AppRouters.list}/:genre',
      name: AppRouters.genreMovies,
      builder: (context, state) {
        final genreName = state.pathParameters['genre']!;
        return GenreMoviesView(genre: genreName);
      },
    ),
    GoRoute(
      path: '/movie-detail',
      builder: (context, state) {
        final movie = state.extra;
        return MovieDetailView(movie: movie as Movie);
      },
    ),

    // --- ANA UYGULAMA (TAB BAR) ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppView(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouters.home,
              builder: (context, state) => const HomeView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouters.list,
              builder: (context, state) => const CategoriesView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRouters.favorites,
              builder: (context, state) => const FavoritesView(),
            ),
          ],
        ),
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
