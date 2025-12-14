import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await MovieManager.instance.fetchGenres();
  await MovieManager.instance.fetchNextPageMovies(initial: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My Movie List',
      debugShowCheckedModeBanner: false, // <-- DEBUG YAZISINI SİLDİK
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.backgroundBlack,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.primaryBlue,
          surface: AppTheme.surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundBlack,
          elevation: 0,
        ),
      ),
      routerConfig: router,
    );
  }
}
