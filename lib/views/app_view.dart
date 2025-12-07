import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart'; // Temayı import et

class AppView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppView({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBarWidget(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Categories'), // İngilizce
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'), // İngilizce
          NavigationDestination(icon: Icon(Icons.recommend), label: 'Recommended'), // İngilizce
        ],
      ),
    );
  }

  AppBar _appBarWidget() {
    return AppBar(
      centerTitle: true, // Ortaya gelsin
      title: Row(
        mainAxisSize: MainAxisSize.min, // Sadece yazı kadar yer kaplasın
        children: [
          const Icon(Icons.movie_filter_rounded, color: AppTheme.primaryBlue), // İkon eklendi
          const SizedBox(width: 10),
          const Text(
            'MY MOVIE LIST', // İngilizce ve Büyük Harf
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w900, // Kalın yazı
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}