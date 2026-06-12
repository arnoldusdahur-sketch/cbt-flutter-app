import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../config/app_config.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  final ThemeService themeService;
  final void Function(ThemeMode) onThemeChanged;
  final void Function(Color) onAccentChanged;
  final ThemeMode currentThemeMode;
  final Color currentAccentColor;

  const SplashScreen({
    super.key,
    required this.themeService,
    required this.onThemeChanged,
    required this.onAccentChanged,
    required this.currentThemeMode,
    required this.currentAccentColor,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for animation + minimum splash time
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Check for updates in background (non-blocking)
    final updateInfo = await UpdateService.checkUpdate();

    // Check if user is logged in
    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    _navigateToMain(isLoggedIn: loggedIn, pendingUpdate: updateInfo);
  }

  void _navigateToMain({required bool isLoggedIn, UpdateInfo? pendingUpdate}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          if (isLoggedIn) {
            return MainShell(
              onThemeChanged: widget.onThemeChanged,
              onAccentChanged: widget.onAccentChanged,
              currentThemeMode: widget.currentThemeMode,
              currentAccentColor: widget.currentAccentColor,
            );
          } else {
            return LoginScreen(
              onThemeChanged: widget.onThemeChanged,
              onAccentChanged: widget.onAccentChanged,
              currentThemeMode: widget.currentThemeMode,
              currentAccentColor: widget.currentAccentColor,
            );
          }
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Platform Simulasi CAT CPNS & PPPK',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 60),

                    // Loading indicator
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Platform.isIOS
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                              radius: 14,
                            )
                          : CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2.5,
                              backgroundColor: primaryColor.withOpacity(0.15),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
