// Dosya: lib/views/auth_view/login_view.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart'; // MovieManager eklendi

String _getMemberName(String email) {
  if (email.contains('@')) {
    return email.substring(0, email.indexOf('@'));
  }
  return 'User';
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  // Giriş mi Kayıt mı modu kontrolü
  bool _isLogin = true;

  // Sloganlar için değişkenler
  int _currentSloganIndex = 0;
  Timer? _sloganTimer;

  final List<String> _slogans = [
    "AVADA KEDAVRA !!!",
    "I'm gonna make him an offer he can't refuse.",
    "You shall not pass!",
    "May the Force be with you.",
    "Why so serious?",
    "To infinity and beyond!",
  ];

  @override
  void initState() {
    super.initState();
    _startSloganRotation();
  }

  void _startSloganRotation() {
    _sloganTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentSloganIndex = (_currentSloganIndex + 1) % _slogans.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _sloganTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    // ŞİFRE UZUNLUĞU KONTROLÜ (Sadece kayıt olurken)
    if (!_isLogin && password.length < 6) {
      _showErrorDialog("Your password must be at least 6 characters long.");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential;

      if (_isLogin) {
        // --- GİRİŞ YAPMA ---
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // [ÖNEMLİ EKLEME]
        // Giriş başarılı oldu, hemen kullanıcının temasını çek!
        await MovieManager.instance.loadUserTheme();
      } else {
        // --- KAYIT OLMA ---
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
      }

      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        if (!_isLogin) {
          // Yeni kayıt ise varsayılan verileri yaz
          await userDoc.set({
            'uid': user.uid,
            'email': user.email?.toLowerCase(),
            'created_at': FieldValue.serverTimestamp(),
            'favorites': [],
            'profile_icon_id': 0,
            'is_dark_mode': true, // Varsayılan tema
          });
        } else {
          // Giriş yapıldıysa ve belge yoksa oluştur (Güvenlik önlemi)
          final snapshot = await userDoc.get();
          if (!snapshot.exists) {
            await userDoc.set({
              'uid': user.uid,
              'email': user.email?.toLowerCase(),
              'created_at': FieldValue.serverTimestamp(),
              'favorites': [],
              'profile_icon_id': 0,
              'is_dark_mode': true,
            });
          }
        }

        final memberName = _getMemberName(email);
        if (mounted) context.go(AppRouters.welcome, extra: memberName);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'The operation failed.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'The username or password is incorrect.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email address is already in use.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'weak-password') {
        message =
            'The password is too weak. It needs to be at least 6 characters long.';
      }
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: <Widget>[
          TextButton(
            child: const Text('OK', style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          // KATMAN 1: ARKA PLAN RESMİ
          Positioned.fill(
            child: Image.asset('assets/bg1.jfif', fit: BoxFit.cover),
          ),

          // KATMAN 2: BLUR
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          // KATMAN 3: İÇERİK
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_filter_rounded,
                    color: AppTheme.primaryBlue,
                    size: 60,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'MyMovieList',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 30,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: Text(
                        _slogans[_currentSloganIndex],
                        key: ValueKey<int>(_currentSloganIndex),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 40),
                  isLoading
                      ? CircularProgressIndicator(color: AppTheme.primaryBlue)
                      : Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                const Color(0xFF1E88E5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              _isLogin ? 'LOG IN' : 'SIGN UP',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                  // Mod Değiştirme Butonu
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign up"
                          : "Do you already have an account? Log in",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
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
