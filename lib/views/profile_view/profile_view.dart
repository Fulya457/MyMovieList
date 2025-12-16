import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Profil Sayfası\n(Detaylar daha sonra eklenecek)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }
}
