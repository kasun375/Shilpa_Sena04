import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gif/gif.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late GifController _controller;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);

    // Add listener to detect when animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    // Safety timeout in case GIF fails to load or notify completion
    Future.delayed(const Duration(seconds: 10), () {
      _navigateToNext();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    if (_navigationStarted || !mounted) return;
    _navigationStarted = true;

    bool isLoggedIn = false;
    try {
      isLoggedIn = FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      debugPrint('FirebaseAuth check failed: $e');
    }

    if (mounted) {
      if (isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Gif(
          image: const AssetImage('assets/images/Comp.gif'),
          controller: _controller,
          autostart: Autostart.once,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
