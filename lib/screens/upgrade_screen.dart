import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  Map<String, dynamic>? _upgradeData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUpgradeInfo();
  }

  Future<void> _loadUpgradeInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.fetchUpgradeInfo();
    if (!mounted) return;

    if (data != null && data['success'] == true) {
      setState(() {
        _upgradeData = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat informasi paket. Periksa koneksi internet Anda.';
      });
    }
  }

  Future<void> _launchWhatsApp() async {
    final cachedUser = await AuthService.getCachedUser();
    final userEmail = cachedUser?['email'] ?? '-';
    final userName = cachedUser?['name'] ?? 'Peserta';

    final text = 'Halo Admin OTWASN, saya ingin melakukan konfirmasi upgrade keanggotaan PRO untuk akun:\nNama: $userName\nEmail: $userEmail.\nMohon panduan untuk proses pembayarannya. Terima kasih.';
    final baseWaUrl = _upgradeData?['whatsapp_url'] ?? 'https://wa.me/6281234567890';
    
    // Parse wa url
    String waUrl = baseWaUrl;
    if (!waUrl.contains('text=')) {
      final connector = waUrl.contains('?') ? '&' : '?';
      waUrl = '$waUrl${connector}text=${Uri.encodeComponent(text)}';
    }

    final url = Uri.parse(waUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp. Silakan hubungi kami secara langsung.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final benefits = _upgradeData?['benefits'] as List? ?? [
      'Akses Seluruh 100+ Simulasi Ujian SKD & SKB',
      'Materi & Modul Eksklusif (TWK, TIU, TKP)',
      'Rapor Hasil Belajar Analitis Lengkap & Pembahasan Soal',
      'Pertemuan Interaktif Live Class Mingguan',
      'Grup WhatsApp Premium & Mentor Bimbingan',
      'Akses Selamanya (Tanpa Batas Waktu)',
    ];

    final price = _upgradeData?['price'] ?? 'Rp 149.000';
    final slashedPrice = _upgradeData?['slashed_price'] ?? 'Rp 299.000';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Upgrade Akun PRO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: textColor, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadUpgradeInfo, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUpgradeInfo,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon Crown
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, size: 54, color: Colors.amber),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mulai Belajar Lebih Efektif!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Akses modul lengkap dan fitur premium OTWASN',
                          style: TextStyle(fontSize: 11.5, color: subColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Benefits List
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manfaat Keanggotaan PRO:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              ...benefits.map((benefit) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            benefit,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: textColor.withOpacity(0.85),
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Pricing Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withBlue(130)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'PROMO BULAN INI',
                                style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slashedPrice,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Akses Selamanya (Sekali Bayar)',
                                style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _launchWhatsApp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Hubungi Admin via WA',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }
}
