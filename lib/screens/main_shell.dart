import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../config/app_config.dart';
import 'dashboard_screen.dart';
import 'native_live_class_screen.dart';
import 'profile_screen.dart';
import 'ebooks_screen.dart';
import 'capaian_screen.dart';
import 'tryout_list_screen.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

class MainShell extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final void Function(Color) onAccentChanged;
  final ThemeMode currentThemeMode;
  final Color currentAccentColor;

  const MainShell({
    super.key,
    required this.onThemeChanged,
    required this.onAccentChanged,
    required this.currentThemeMode,
    required this.currentAccentColor,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  ThemeService? _themeService;
  bool _themeServiceReady = false;

  @override
  void initState() {
    super.initState();
    _initThemeService();
    _checkAppUpdate();
  }

  Future<void> _checkAppUpdate() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final updateInfo = await UpdateService.checkUpdate();
        if (updateInfo != null && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => UpdateDialog(updateInfo: updateInfo),
          );
        }
      } catch (_) {}
    });
  }

  Future<void> _initThemeService() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _themeService = ThemeService(prefs);
        _themeServiceReady = true;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (!_themeServiceReady) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screens = [
      DashboardScreen(onTabRequest: _onTabTapped),
      const NativeLiveClassScreen(),
      const CapaianScreen(),
      ProfileScreen(
        themeService: _themeService!,
        currentThemeMode: widget.currentThemeMode,
        currentAccentColor: widget.currentAccentColor,
        onThemeChanged: widget.onThemeChanged,
        onAccentChanged: widget.onAccentChanged,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TryoutListScreen(initialCategory: 'skd'),
              ),
            );
          },
          backgroundColor: primaryColor,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  Color.lerp(primaryColor, Colors.white, 0.2) ?? primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.edit_document,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.zero,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 8,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(0, Icons.home_rounded, 'Beranda', isDark, primaryColor),
              _buildTabItem(1, Icons.video_camera_front_rounded, 'Live Class', isDark, primaryColor),
              const SizedBox(width: 48), // Space for floating action button
              _buildTabItem(2, Icons.leaderboard_rounded, 'Rapor', isDark, primaryColor),
              _buildTabItem(3, Icons.person_rounded, 'Profil', isDark, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label, bool isDark, Color primaryColor) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? primaryColor
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
