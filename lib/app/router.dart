// Dosya: lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// View Importları
import 'package:mymovielist/views/app_view.dart';
import 'package:mymovielist/views/login_view/login_view.dart';
import 'package:mymovielist/views/login_view/welcome_screen.dart';
import 'package:mymovielist/views/home_view/home_view.dart';
import 'package:mymovielist/views/categories_view/categories_view.dart';
import 'package:mymovielist/views/categories_view/genre_movies_view.dart';
import 'package:mymovielist/views/favorites_view/favorites_view.dart';
import 'package:mymovielist/views/recommended_view/recommended_view.dart';

// Detay Sayfaları
import 'package:mymovielist/views/home_view/movie_detail_view.dart';
import 'package:mymovielist/views/home_view/personal_detail_view.dart';

// Profil ve Sosyal Sayfalar
import 'package:mymovielist/views/profile_view/profile_view.dart';
import 'package:mymovielist/views/profile_view/friends_view.dart';
import 'package:mymovielist/views/profile_view/notifications_view.dart';
import 'package:mymovielist/views/profile_view/chat_view.dart';
import 'package:mymovielist/views/profile_view/user_lists_view.dart';
import 'package:mymovielist/views/profile_view/user_list_detail_view.dart';
import 'package:mymovielist/views/profile_view/user_reviews_view.dart';

// Modeller
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- 1. SABİT YOLLAR (CONSTANTS) ---
class AppRouters {
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String list = '/list';
  static const String favorites = '/favorites';
  static const String recommends = '/recommends';
  static const String genreMovies = '/genre/:genre';

  // Detaylar
  static const String movieDetail = '/movie-detail';
  static const String personDetail = '/person-detail';

  // Profil ve Sosyal
  static const String profile = '/profile'; // <-- İsim tanımlıydı
  static const String friends = '/friends';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String userLists = '/user-lists';
  static const String userListDetail = '/user-list-detail';
  static const String userReviews = '/user-reviews';
}

// --- 2. ROUTER AYARLARI ---
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorList = GlobalKey<NavigatorState>(debugLabel: 'shellList');
final _shellNavigatorFav = GlobalKey<NavigatorState>(debugLabel: 'shellFav');
final _shellNavigatorRec = GlobalKey<NavigatorState>(debugLabel: 'shellRec');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRouters.login,
  routes: [
    // 1. Giriş ve Karşılama
    GoRoute(
      path: AppRouters.login,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: AppRouters.welcome,
      builder: (context, state) {
        final name = state.extra as String? ?? 'Kullanıcı';
        return WelcomeScreen(userName: name);
      },
    ),

    // 2. Detay Sayfaları (Alt menüden bağımsız tam ekran açılırlar)
    GoRoute(
      path: AppRouters.movieDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        if (state.extra is! Movie) {
          return const Scaffold(
            body: Center(child: Text("Hata: Film verisi yok")),
          );
        }
        return MovieDetailView(movie: state.extra as Movie);
      },
    ),
    GoRoute(
      path: AppRouters.personDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        if (state.extra is! Person) {
          return const Scaffold(
            body: Center(child: Text("Hata: Kişi verisi yok")),
          );
        }
        return PersonDetailView(person: state.extra as Person);
      },
    ),
    GoRoute(
      path: AppRouters.genreMovies,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final genreName = state.pathParameters['genre']!;
        return GenreMoviesView(genre: genreName);
      },
    ),

    // --- SOSYAL SAYFALAR ---

    // !!! İŞTE EKSİK OLAN PARÇA BURASIYDI: PROFİL SAYFASI !!!
    GoRoute(
      path: AppRouters.profile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileView(),
    ),

    // -------------------------------------------------------
    GoRoute(
      path: AppRouters.friends,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FriendsView(),
    ),
    GoRoute(
      path: AppRouters.notifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsView(),
    ),
    GoRoute(
      path: AppRouters.chat,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return ChatView(extras: extras);
      },
    ),
    GoRoute(
      path: AppRouters.userLists,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UserListsView(),
    ),
    GoRoute(
      path: AppRouters.userReviews,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UserReviewsView(),
    ),
    GoRoute(
      path: AppRouters.userListDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return UserListDetailView(
          listId: data['listId'],
          listName: data['listName'],
          items: data['items'],
          type: data['type'],
        );
      },
    ),
    GoRoute(
      path: AppRouters.genreMovies, // '/genre/:genre'
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        // Parametreyi al (örn: Action)
        final genreName = state.pathParameters['genre'] ?? 'Generic';
        return GenreMoviesView(genre: genreName);
      },
    ),

    // 3. ANA UYGULAMA (ALT MENÜLÜ YAPI)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppView(navigationShell: navigationShell),
      branches: [
        // A. Home Tab
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHome,
          routes: [
            GoRoute(
              path: AppRouters.home,
              builder: (context, state) => const HomeView(),
            ),
          ],
        ),
        // B. Categories Tab
        // B. Categories Tab (GÜNCELLENMİŞ HALİ)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorList,
          routes: [
            GoRoute(
              path: AppRouters.list,
              builder: (context, state) => const CategoriesView(),
              // ↓↓↓ BU KISMI EKLİYORUZ ↓↓↓
              routes: [
                GoRoute(
                  path: ':genre', // Bu sayede '/list/Action' çalışacak
                  parentNavigatorKey: _rootNavigatorKey, // Alt menüyü gizle
                  builder: (context, state) {
                    final genreName =
                        state.pathParameters['genre'] ?? 'Generic';
                    return GenreMoviesView(genre: genreName);
                  },
                ),
              ],
              // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
            ),
          ],
        ),
        // C. Favorites Tab
        StatefulShellBranch(
          navigatorKey: _shellNavigatorFav,
          routes: [
            GoRoute(
              path: AppRouters.favorites,
              builder: (context, state) => const FavoritesView(),
            ),
          ],
        ),
        // D. Recommended (For You) Tab
        StatefulShellBranch(
          navigatorKey: _shellNavigatorRec,
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

  // Yönlendirme Koruması (Guard)
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.uri.toString() == AppRouters.login;
    final isWelcome = state.uri.toString() == AppRouters.welcome;

    if (user == null && !isLoggingIn) {
      return AppRouters.login;
    }

    if (user != null && isLoggingIn) {
      return AppRouters.home;
    }

    return null;
  },
);
