import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestVersionCode;
  final String downloadUrl;
  final String ipaUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.downloadUrl,
    required this.ipaUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['version'] ?? '',
      latestVersionCode: json['versionCode'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? AppConfig.apkDownloadUrl,
      ipaUrl: json['ipaUrl'] ?? 'https://otwasn.my.id/downloads/otwasn.ipa',
      releaseNotes: json['releaseNotes'] ?? 'Perbaikan bug dan peningkatan performa.',
    );
  }
}

class UpdateService {
  /// Returns UpdateInfo if an update is available, or null if up-to-date.
  static Future<UpdateInfo?> checkUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.versionCheckUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(data);

      if (info.latestVersionCode > AppConfig.appVersionCode) {
        return info;
      }
      return null;
    } catch (_) {
      return null; // Silent fail — don't block app startup
    }
  }

  /// Download APK to cache directory (Android only).
  /// Returns the downloaded file path, or null on failure.
  static Future<String?> downloadApk(
    UpdateInfo info,
    void Function(double progress) onProgress,
  ) async {
    try {
      Directory dir;
      if (Platform.isAndroid) {
        final extDirs = await getExternalCacheDirectories();
        if (extDirs != null && extDirs.isNotEmpty) {
          dir = extDirs.first;
        } else {
          dir = await getTemporaryDirectory();
        }
      } else {
        dir = await getTemporaryDirectory();
      }

      final filePath = '${dir.path}/otwasn_update.apk';
      final file = File(filePath);

      // Clean up previous download file if it exists to prevent issues
      if (await file.exists()) {
        await file.delete();
      }

      final request = http.Request('GET', Uri.parse(info.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) return null;

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(downloadedBytes / totalBytes);
        }
      }

      await sink.close();
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
