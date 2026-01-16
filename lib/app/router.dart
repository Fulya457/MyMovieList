// Dosya: lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
import 'package:mymovielist/views/profile_view/admin_panel_view.dart'; // Admin Panel importu
import 'package:mymovielist/app/groups_view.dart';
import 'package:mymovielist/app/group_chat_view.dart';

// Modeller
import 'package:mymovielist/models/movie_model.dart';
import 'package:mymovielist/models/person_model.dart';

// --- 1. SABİT YOLLAR (CONSTANTS) ---
class AppRouters {
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String favorites = '/favorites';
  static const String recommends = '/recommends';
  static const String genreMovies = 'genre-movies';

  // Detaylar
  static const String movieDetail = '/movie-detail';
  static const String personDetail = '/person-detail';

  // Profil ve Sosyal
  static const String profile = '/profile';
  static const String friends = '/friends';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String userLists = '/user-lists';
  static const String userListDetail = '/user-list-detail';
  static const String userReviews = '/user-reviews';
  static const String groups = '/groups';
  static const String groupChat = '/group-chat';

  // Admin [EKLENDİ]
  static const String adminPanel = '/admin-panel';
}

// --- 2. ROUTER AYARLARI ---
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorCat = GlobalKey<NavigatorState>(debugLabel: 'shellCat');
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

    // 2. Detay Sayfaları (Alt menüden bağımsız tam ekran açılırlar - Root Navigator)
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
    // Tür Sayfası
    GoRoute(
      path: '/genre/:genre',
      name: AppRouters.genreMovies,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final genreName = state.pathParameters['genre'] ?? 'Generic';
        return GenreMoviesView(genre: genreName);
      },
    ),

    // --- SOSYAL SAYFALAR (Profil Altındakiler) ---
    GoRoute(
      path: AppRouters.profile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileView(),
    ),
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

    // --- ADMIN PANEL ROTASI [EKLENDİ] ---
    GoRoute(
      path: AppRouters.adminPanel,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminPanelView(),
    ),

    // --- GRUP ROTALARI ---
    GoRoute(
      path: AppRouters.groups,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GroupsView(),
    ),
    GoRoute(
      path: AppRouters.groupChat,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return GroupChatView(
          groupId: data['groupId'],
          groupName: data['groupName'],
          isCreator: data['isCreator'] ?? false,
          groupIconUrl: data['groupIconUrl'],
          sharedMovie: data['sharedMovie'],
        );
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
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCat,
          routes: [
            GoRoute(
              path: AppRouters.categories,
              builder: (context, state) => const CategoriesView(),
              routes: [
                GoRoute(
                  path: ':genre',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final genreName =
                        state.pathParameters['genre'] ?? 'Generic';
                    return GenreMoviesView(genre: genreName);
                  },
                ),
              ],
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
