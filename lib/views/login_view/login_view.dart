import 'dart:async';
import 'dart:ui'; // Blur efekti için
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Animasyonlu yazı için değişkenler
  int _textIndex = 0;
  final List<String> _loadingTexts = [
    "Loading Scenes...",
    "Preparing Popcorn...",
    "Dimming Lights...",
    "Welcome to Cinema..."
  ];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Yazıları 2 saniyede bir değiştir
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _textIndex = (_textIndex + 1) % _loadingTexts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final user = _usernameController.text;
    final pass = _passwordController.text;

    // Şifre Kontrolü: a / b
    if (user == 'a' && pass == 'b') {
      context.go(AppRouters.home); // Başarılıysa Home'a git
    } else {
      // Hata Mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect username or password!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. ARKA PLAN (Sanki film izleniyor) ---
          Image.network(
            "https://m.media-amazon.com/images/M/MV5BMDFkYTc0MGEtZmNhMC00ZDIzLWFmNTEtODM1ZmRlYWMwMWFmXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_QL75_UX380_CR0,4,380,562_.jpg",
            fit: BoxFit.cover,
          ),

          // --- 2. BLUR EFEKTİ (Televizyon hissi) ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.6), // Hafif karartma
            ),
          ),

          // --- 3. İÇERİK ---
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo ve Animasyonlu Yazı
                  const Icon(Icons.movie_filter, size: 80, color: AppTheme.primaryBlue),
                  const SizedBox(height: 20),
                  
                  // Animasyonlu Yazı (Fade Effect)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      _loadingTexts[_textIndex],
                      key: ValueKey<int>(_textIndex),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Kullanıcı Adı
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: const Icon(Icons.person, color: AppTheme.primaryBlue),
                      hintText: "Username (a)",
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Şifre
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryBlue),
                      hintText: "Password (b)",
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Giriş Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 10,
                        shadowColor: AppTheme.primaryBlue.withOpacity(0.5),
                      ),
                      child: const Text(
                        "ENTER THEATER",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}