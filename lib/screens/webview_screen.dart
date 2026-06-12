import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../widgets/offline_screen.dart';
import '../widgets/update_dialog.dart';
import 'settings_screen.dart';

class WebViewScreen extends StatefulWidget {
  final ThemeService themeService;
  final void Function(ThemeMode) onThemeChanged;
  final void Function(Color) onAccentChanged;
  final ThemeMode currentThemeMode;
  final Color currentAccentColor;
  final UpdateInfo? pendingUpdate;

  const WebViewScreen({
    super.key,
    required this.themeService,
    required this.onThemeChanged,
    required this.onAccentChanged,
    required this.currentThemeMode,
    required this.currentAccentColor,
    this.pendingUpdate,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isOffline = false;
  double _loadProgress = 0;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _initWebView();

    // Show update dialog after first frame
    if (widget.pendingUpdate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog(widget.pendingUpdate!);
      });
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _isOffline = false;
            });
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _controller.canGoBack().then((can) {
              setState(() => _canGoBack = can);
            });
          },
          onProgress: (progress) {
            setState(() => _loadProgress = progress / 100.0);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              setState(() {
                _isOffline = true;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Keep internal OTWASN navigation in-app
            if (url.contains('otwasn.my.id') ||
                url.contains('toefl.otwasn.my.id')) {
              return NavigationDecision.navigate;
            }
            // External links: open with system browser (not implemented here for simplicity)
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(_buildUserAgent())
      ..loadRequest(Uri.parse(AppConfig.baseUrl));
  }

  String _buildUserAgent() {
    final platform = Platform.isAndroid ? 'Android' : 'iOS';
    return 'Mozilla/5.0 ($platform) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0 Mobile Safari/537.36 ${AppConfig.userAgentSuffix}';
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result.isNotEmpty && !result.contains(ConnectivityResult.none)) {
      setState(() => _isOffline = false);
      _controller.reload();
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(updateInfo: info),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          themeService: widget.themeService,
          currentThemeMode: widget.currentThemeMode,
          currentAccentColor: widget.currentAccentColor,
          onThemeChanged: widget.onThemeChanged,
          onAccentChanged: widget.onAccentChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          // Show exit confirmation
          if (!context.mounted) return;
          final shouldExit = Platform.isIOS
              ? await showCupertinoDialog<bool>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('Keluar Aplikasi?'),
                    content: const Text('Apakah Anda yakin ingin keluar dari OTWASN?'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF8E8E93))),
                      ),
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(ctx, true),
                        isDestructiveAction: true,
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                )
              : await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Keluar Aplikasi?', style: TextStyle(fontWeight: FontWeight.w700)),
                    content: const Text('Apakah Anda yakin ingin keluar dari OTWASN?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Batal', style: TextStyle(color: primaryColor)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // Offline screen
            if (_isOffline)
              OfflineScreen(onRetry: _checkConnectivity),

            // WebView (hidden when offline)
            if (!_isOffline)
              SafeArea(
                child: Column(
                  children: [
                    // Top bar with settings button
                    _buildTopBar(isDark, primaryColor),

                    // Progress indicator
                    if (_isLoading && _loadProgress < 1.0)
                      LinearProgressIndicator(
                        value: _loadProgress,
                        backgroundColor: Colors.transparent,
                        color: primaryColor,
                        minHeight: 3,
                      ),

                    // WebView
                    Expanded(
                      child: WebViewWidget(controller: _controller),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color primaryColor) {
    final isIOS = Platform.isIOS;
    
    if (isIOS) {
      // iOS Navigation Bar Style (centered title, Cupertino icons)
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
            ),
          ),
        ),
        child: NavigationToolbar(
          leading: _canGoBack
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _controller.goBack(),
                  child: Icon(
                    CupertinoIcons.back,
                    size: 24,
                    color: primaryColor,
                  ),
                )
              : const SizedBox(width: 16),
          middle: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: primaryColor.withOpacity(0.25)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'OTWASN',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _openSettings,
            child: Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 22,
              color: primaryColor,
            ),
          ),
        ),
      );
    }

    // Android Navigation Bar Style (left-aligned title, Material icons)
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (_canGoBack)
            IconButton(
              onPressed: () => _controller.goBack(),
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              tooltip: 'Kembali',
            )
          else
            const SizedBox(width: 16),

          // Logo + App name
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withOpacity(0.25)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'OTWASN',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          // Settings button
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded, size: 22),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
