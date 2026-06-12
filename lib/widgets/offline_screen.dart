import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ========================================
// Offline Screen Widget
// ========================================
class OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflineScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final isIOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isIOS ? 22 : 24),
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Icon(
                    isIOS ? CupertinoIcons.wifi_slash : Icons.signal_wifi_off_rounded,
                    size: 42,
                    color: isIOS ? CupertinoColors.systemBlue : subColor,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  isIOS ? 'Koneksi Terputus' : 'Tidak Ada Koneksi',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w800, 
                    color: textColor,
                    letterSpacing: isIOS ? -0.5 : 0,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Pastikan Wi-Fi atau data seluler Anda aktif, lalu coba lagi.',
                  style: TextStyle(fontSize: 14, color: subColor, height: 1.6),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: isIOS
                      ? CupertinoButton(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: onRetry,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.refresh, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Coba Lagi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
