import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/views/app_view.dart';
import 'package:mymovielist/views/favorites_view/favorites_view.dart';
import 'package:mymovielist/views/home_view/home_view.dart';
import 'package:mymovielist/views/recommended_view/recommended_view.dart';
import 'package:mymovielist/views/list_view/list_view.dart';

// --- BU SATIRI MUTLAKA EKLE ---
import 'package:mymovielist/views/login_view/login_view.dart'; 
// ------------------------------

final _rooterKey = GlobalKey<NavigatorState>();

class AppRouters {
  static const String login = '/login';
  static const String home = '/';
  static const String favorites = '/favorites';
  static const String list = '/list';
  static const String recommends = '/recommends';
}

final router = GoRouter(
  navigatorKey: _rooterKey,
  initialLocation: AppRouters.login, // Açılış sayfası Login
  routes: [
    // --- LOGIN ROUTE ---
    GoRoute(
      path: AppRouters.login,
      builder: (context, state) => const LoginView(),
    ),

    // --- ANA UYGULAMA ---
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
              builder: (context, state) => const MyListView(),
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