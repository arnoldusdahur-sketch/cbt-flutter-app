import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';

// ========================================
// Update Dialog Widget
// ========================================
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _statusText = '';
  static const _platform = MethodChannel('com.example.otwasn_app/install');

  Future<void> _startDownload() async {
    if (!Platform.isAndroid) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _statusText = 'Mengunduh pembaruan... 0%';
    });

    try {
      final filePath = await UpdateService.downloadApk(
        widget.updateInfo,
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _statusText = 'Mengunduh pembaruan... ${(progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      if (filePath != null) {
        setState(() {
          _statusText = 'Menyiapkan pemasangan...';
        });

        // Trigger native APK installer
        final success = await _platform.invokeMethod<bool>('installApk', {'filePath': filePath});
        if (success == true) {
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          throw Exception('Gagal menjalankan installer sistem.');
        }
      } else {
        throw Exception('Gagal mengunduh berkas APK.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Pembaruan gagal.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembaruan gagal: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _openIpaUrl() async {
    final url = Uri.parse(widget.updateInfo.ipaUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fail silently or fallback
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }



  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS Platform Native Cupertino Dialog
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: const Text(
          'Pembaruan Tersedia! 🎉',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Versi ${widget.updateInfo.latestVersion} sudah tersedia untuk iPhone Anda.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark 
                    ? CupertinoColors.activeBlue.withOpacity(0.12) 
                    : CupertinoColors.activeBlue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark 
                      ? CupertinoColors.activeBlue.withOpacity(0.25) 
                      : CupertinoColors.activeBlue.withOpacity(0.15),
                ),
              ),
              child: Text(
                widget.updateInfo.releaseNotes,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  height: 1.4,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          CupertinoDialogAction(
            onPressed: _openIpaUrl,
            isDefaultAction: true,
            child: const Text('Pembaruan'),
          ),
        ],
      );
    }

    // Android/Material Dialog
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: primaryColor.withOpacity(0.12),
                border: Border.all(color: primaryColor.withOpacity(0.25)),
              ),
              child: Icon(Icons.system_update_alt_rounded, color: primaryColor, size: 32),
            ),

            const SizedBox(height: 18),

            Text('Pembaruan Tersedia! 🎉',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),

            const SizedBox(height: 8),

            Text(
              'Versi ${widget.updateInfo.latestVersion} sudah tersedia.',
              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.15)),
              ),
              child: Text(
                widget.updateInfo.releaseNotes,
                style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), height: 1.5),
              ),
            ),

            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: primaryColor.withOpacity(0.15),
                color: primaryColor,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(_statusText, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isDownloading ? null : () => Navigator.pop(context),
                    child: Text('Nanti', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isDownloading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Update Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
