import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../widgets/offline_screen.dart';

class WebViewTabScreen extends StatefulWidget {
  final String initialUrl;
  final String title;

  const WebViewTabScreen({
    super.key,
    required this.initialUrl,
    required this.title,
  });

  @override
  State<WebViewTabScreen> createState() => _WebViewTabScreenState();
}

class _WebViewTabScreenState extends State<WebViewTabScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isOffline = false;
  double _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _isOffline = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadProgress = progress / 100.0);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              if (mounted) {
                setState(() {
                  _isOffline = true;
                  _isLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('otwasn.my.id') || url.contains('toefl.otwasn.my.id')) {
              return NavigationDecision.navigate;
            }
            // Launch external URLs (like Google Meet, Zoom, WhatsApp, etc.) in system app
            _launchExternalUrl(url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..setUserAgent(_buildUserAgent());

    _setCookiesAndLoad(widget.initialUrl);
  }

  String _buildUserAgent() {
    final platform = Platform.isAndroid ? 'Android' : 'iOS';
    return 'Mozilla/5.0 ($platform) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0 Mobile Safari/537.36 ${AppConfig.userAgentSuffix}';
  }

  Future<void> _setCookiesAndLoad(String url) async {
    debugPrint('WebViewTabScreen: Loading URL: $url');
    Map<String, String> headers = {
      'User-Agent': _buildUserAgent(),
    };
    try {
      final sessionToken = await AuthService.getSessionCookieValue();
      debugPrint('WebViewTabScreen: Retrieved sessionToken = "$sessionToken"');
      if (sessionToken.isNotEmpty) {
        final decodedToken = Uri.decodeComponent(sessionToken);
        final uri = Uri.parse(url);
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['app_session_token'] = decodedToken;
        url = uri.replace(queryParameters: queryParams).toString();
        debugPrint('WebViewTabScreen: Appended session token (decoded then re-encoded) to URL: $url');
      } else {
        debugPrint('WebViewTabScreen: sessionToken is EMPTY!');
      }

      final cookieString = await AuthService.getSessionCookie();
      debugPrint('WebViewTabScreen: Retrieved cookieString = "$cookieString"');
      if (cookieString.isNotEmpty) {
        // Prepare Cookie header with decoded values if we need to pass them raw,
        // but wait: for the HTTP headers, we should pass them as they are or decoded?
        // Actually, the headers parameter in loadRequest is used by the WebView HTTP request.
        // It's safest to decode the values before setting them in headers and WebViewCookieManager.
        // Wait, standard HTTP cookie header expects URL-encoded values. But since WebViewCookieManager
        // sets them in the browser jar, the browser jar will send the cookies automatically in all HTTP requests!
        // So we don't strictly need to pass the 'Cookie' header in loadRequest headers,
        // because WebViewCookieManager already injects them globally for that domain!
        // But to be safe, let's keep the header. Let's make sure the header contains the properly formatted cookies.
        
        final cookieManager = WebViewCookieManager();
        final uri = Uri.parse(AppConfig.baseUrl);
        final domain = uri.host;

        final pairs = cookieString.split('; ');
        final List<String> headerCookiePairs = [];
        for (final pair in pairs) {
          final eq = pair.indexOf('=');
          if (eq > 0) {
            final name = pair.substring(0, eq).trim();
            final value = pair.substring(eq + 1).trim();
            
            // Decode the value to get the raw un-encoded cookie value
            final decodedValue = Uri.decodeComponent(value);
            debugPrint('WebViewTabScreen: Injecting cookie: $name = [hidden] (decoded) for domain: $domain');
            
            // Set cookie for otwasn.my.id
            await cookieManager.setCookie(
              WebViewCookie(
                name: name,
                value: decodedValue,
                domain: domain,
                path: '/',
              ),
            );
            
            // Set cookie for .otwasn.my.id
            await cookieManager.setCookie(
              WebViewCookie(
                name: name,
                value: decodedValue,
                domain: '.$domain',
                path: '/',
              ),
            );

            headerCookiePairs.add('$name=$value'); // Keep encoded in headers
          }
        }
        headers['Cookie'] = headerCookiePairs.join('; ');
      } else {
        debugPrint('WebViewTabScreen: cookieString is EMPTY!');
      }
    } catch (e) {
      debugPrint('WebViewTabScreen: Error setting cookies: $e');
    }

    if (mounted) {
      debugPrint('WebViewTabScreen: Loading request with URL: $url and headers: $headers');
      _controller.loadRequest(Uri.parse(url), headers: headers);
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString.trim());
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result.isNotEmpty && !result.contains(ConnectivityResult.none)) {
      setState(() => _isOffline = false);
      _setCookiesAndLoad(widget.initialUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        bottom: _isLoading && _loadProgress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadProgress,
                  backgroundColor: Colors.transparent,
                  color: primaryColor,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          if (_isOffline)
            OfflineScreen(onRetry: _checkConnectivity),
          if (!_isOffline)
            WebViewWidget(controller: _controller),
        ],
      ),
    );
  }
}
