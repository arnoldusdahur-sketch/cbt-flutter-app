import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1E293B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  final themeService = ThemeService(prefs);

  runApp(OtwAsnApp(themeService: themeService));
}

class OtwAsnApp extends StatefulWidget {
  final ThemeService themeService;

  const OtwAsnApp({super.key, required this.themeService});

  @override
  State<OtwAsnApp> createState() => _OtwAsnAppState();
}

class _OtwAsnAppState extends State<OtwAsnApp> {
  late ThemeMode _themeMode;
  late Color _accentColor;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeService.getThemeMode();
    _accentColor = widget.themeService.getAccentColor();
  }

  void _updateTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.themeService.saveThemeMode(mode);
  }

  void _updateAccentColor(Color color) {
    setState(() => _accentColor = color);
    widget.themeService.saveAccentColor(color);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme(_accentColor),
      darkTheme: AppTheme.darkTheme(_accentColor),
      home: SplashScreen(
        themeService: widget.themeService,
        onThemeChanged: _updateTheme,
        onAccentChanged: _updateAccentColor,
        currentThemeMode: _themeMode,
        currentAccentColor: _accentColor,
      ),
    );
  }
}
