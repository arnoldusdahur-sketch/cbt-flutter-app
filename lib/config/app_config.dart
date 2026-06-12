class AppConfig {
  // App Info
  static const String appName = 'OTWASN';
  static const String appFullName = 'OTWASN - Simulasi CAT CPNS & PPPK';
  static const String appVersion = '1.2.4';
  static const int appVersionCode = 8;

  // URLs
  static const String baseUrl = 'https://otwasn.my.id';
  static const String versionCheckUrl = '$baseUrl/downloads/version.json';
  static const String apkDownloadUrl = '$baseUrl/downloads/otwasn_flutter.apk';

  // Custom User-Agent — Laravel middleware checks this to allow access
  static const String userAgentSuffix = 'OtwAsnFlutter/1.0';

  // Support
  static const String whatsappSupport = 'https://wa.me/6281234567890';
}
