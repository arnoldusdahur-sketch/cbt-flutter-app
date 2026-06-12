import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'webview_tab_screen.dart';
import 'upgrade_screen.dart';

class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key});

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  Map<String, dynamic>? _liveClassData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLiveClasses();
  }

  Future<void> _loadLiveClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.fetchLiveClass();
    if (!mounted) return;

    if (data != null && data['success'] == true) {
      setState(() {
        _liveClassData = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat jadwal kelas. Periksa koneksi internet Anda.';
      });
    }
  }

  Future<void> _joinMeet(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final url = Uri.parse(urlString.trim());
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka link bimbingan: $urlString')),
        );
      }
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString);
      final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year} | ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final hasPackage = _liveClassData?['has_package'] == true;
    final upcoming = _liveClassData?['upcoming_classes'] as List? ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Live Class & Bimbel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_camera_front_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: textColor, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadLiveClasses, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLiveClasses,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Promotion or Active Bimbel Banner
                      if (!hasPackage)
                        _buildPromoCard(context, primaryColor)
                      else
                        _buildBimbelActiveCard(context, primaryColor),

                      const SizedBox(height: 24),

                      // Schedule Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jadwal Bimbingan Live',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          Text(
                            '${upcoming.length} Kelas',
                            style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Schedule List
                      if (upcoming.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 36, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada jadwal kelas bimbingan terdekat.',
                                style: TextStyle(color: subColor, fontSize: 11.5),
                              ),
                            ],
                          ),
                        )
                      else
                        ...upcoming.map((lc) => _buildLiveClassCard(context, lc, hasPackage, isDark, primaryColor, textColor, subColor)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPromoCard(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withBlue(150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Bimbingan Live Class PRO',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ikuti pembahasan soal interaktif bersama tentor berpengalaman via Zoom & Google Meet untuk persiapan CPNS & PPPK 2026.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpgradeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: const Text('Gabung Bimbel Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildBimbelActiveCard(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF10B981),
            radius: 16,
            child: Icon(Icons.check, color: Colors.white, size: 16),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paket Bimbel Aktif',
                  style: TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Anda memiliki akses penuh untuk mengikuti semua Live Class.',
                  style: TextStyle(color: Color(0xFF047857), fontSize: 10.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClassCard(
    BuildContext context,
    Map<String, dynamic> lc,
    bool hasPackage,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subColor,
  ) {
    final title = lc['title'] ?? 'Live Class';
    final description = lc['description'] ?? '';
    final tutor = lc['tutor_name'] ?? 'Mentor OTWASN';
    final startTimeStr = _formatDateTime(lc['start_time']);
    final isBooked = lc['is_booked'] == true;
    final meetLink = lc['meet_link'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            'Tutor: $tutor',
            style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: subColor, height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: subColor),
              const SizedBox(width: 4),
              Text(startTimeStr, style: TextStyle(fontSize: 10, color: subColor)),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          if (!hasPackage)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 14),
                label: const Text('Beli Paket Bimbel', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          else if (!isBooked)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () {
                  // Book live class via Laravel Web (keeps session sync)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WebViewTabScreen(
                        initialUrl: '${AppConfig.baseUrl}/live-class',
                        title: 'Daftar Live Class',
                      ),
                    ),
                  ).then((_) => _loadLiveClasses());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Daftar Kelas (Gratis)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sudah Terdaftar',
                      style: TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (meetLink != null && meetLink.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => _joinMeet(meetLink),
                      icon: const Icon(Icons.videocam_rounded, size: 14),
                      label: const Text('Gabung Meet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
