import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/router.dart';
import 'package:mymovielist/app/theme.dart';

class WelcomeScreen extends StatefulWidget {
  final String userName;
  const WelcomeScreen({super.key, required this.userName});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double opacityLevel = 0.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          opacityLevel = 1.0;
        });
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go(AppRouters.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Center(
        child: AnimatedOpacity(
          opacity: opacityLevel,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeIn,
          child: Text(
            'Hello, ${widget.userName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black54,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
