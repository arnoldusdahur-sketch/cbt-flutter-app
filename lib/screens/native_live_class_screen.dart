import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

class NativeLiveClassScreen extends StatefulWidget {
  const NativeLiveClassScreen({super.key});

  @override
  State<NativeLiveClassScreen> createState() => _NativeLiveClassScreenState();
}

class _NativeLiveClassScreenState extends State<NativeLiveClassScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  int? _selectedPackageId;
  String? _selectedPackageName;
  int _userQuota = 0;
  bool _hasLiveClassAccess = false;

  List<dynamic> _packages = [];
  List<dynamic> _classes = [];
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveClassData();
  }

  // Get User-Agent
  String _userAgent() {
    return 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0 Mobile Safari/537.36 ${AppConfig.userAgentSuffix}';
  }

  // Fetch data
  Future<void> _fetchLiveClassData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cookie = await AuthService.getSessionCookie();
      String urlStr = '${AppConfig.baseUrl}/api/mobile/live-class';
      if (_selectedPackageId != null) {
        urlStr += '?package_id=$_selectedPackageId';
      }

      final resp = await http.get(
        Uri.parse(urlStr),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception('Gagal memuat data kelas bimbingan.');
      }

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        if (mounted) {
          setState(() {
            if (_selectedPackageId != null) {
              _classes = data['upcoming_classes'] ?? [];
            } else {
              _packages = data['packages'] ?? [];
              _userQuota = data['user_quota'] ?? 0;
              _hasLiveClassAccess = data['has_live_class_access'] == true;
            }
            _isLoading = false;
          });
        }
      } else {
        throw Exception(data['message'] ?? 'Gagal memproses data.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // Book a live class session
  Future<void> _bookClass(int classId) async {
    setState(() {
      _isProcessingAction = true;
    });

    try {
      final cookie = await AuthService.getSessionCookie();
      final resp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/live-class/$classId/book'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Berhasil memesan sesi kelas!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _fetchLiveClassData();
      } else {
        throw Exception(data['message'] ?? 'Gagal mendaftar sesi kelas.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  // Select bimbel package
  Future<void> _selectPackage(int packageId) async {
    setState(() {
      _isProcessingAction = true;
    });

    try {
      final cookie = await AuthService.getSessionCookie();
      final resp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/live-class/select-package/$packageId'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Berhasil mendaftar di paket bimbingan!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _fetchLiveClassData();
      } else {
        throw Exception(data['message'] ?? 'Gagal mendaftar paket.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  // Join meeting link (Zoom / GMeet)
  Future<void> _joinMeeting(String? link) async {
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan kelas (Zoom/Meet) belum tersedia atau belum di-input mentor.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final url = Uri.parse(link.trim());
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Tidak dapat membuka tautan eksternal.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka Zoom/Meet: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // Format date readable
  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final days = [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
      ];
      
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');

      return '$dayName, ${dt.day} $monthName - $hour:$minute WIB';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedPackageId != null
              ? (_selectedPackageName ?? 'Jadwal Kelas')
              : 'Live Class & Bimbingan',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        leading: _selectedPackageId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _selectedPackageId = null;
                    _selectedPackageName = null;
                    _classes = [];
                  });
                  _fetchLiveClassData();
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _fetchLiveClassData,
                              child: const Text('Coba Lagi'),
                            )
                          ],
                        ),
                      ),
                    )
                  : _selectedPackageId != null
                      ? _buildUpcomingClassesView(isDark)
                      : _buildPackagesCatalogView(isDark),
          if (_isProcessingAction)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  // --- 1. View: Packages Catalog ---
  Widget _buildPackagesCatalogView(bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paket Bimbingan Belajar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_hasLiveClassAccess)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sisa Kuota: $_userQuota kali',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Silakan pilih paket bimbingan belajar aktif Anda untuk melihat jadwal dan daftar sesi bimbingan live.',
            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          _packages.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Belum ada paket bimbel aktif saat ini.')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final pkg = _packages[index];
                    final name = pkg['name'] ?? '';
                    final desc = pkg['description'] ?? '';
                    final features = pkg['features'] as List<dynamic>? ?? [];
                    final isRegistered = pkg['is_registered'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isRegistered
                              ? Colors.green.withOpacity(0.4)
                              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03)),
                          width: isRegistered ? 1.5 : 1.0,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: isRegistered
                            ? () {
                                setState(() {
                                  _selectedPackageId = pkg['id'];
                                  _selectedPackageName = pkg['name'];
                                });
                                _fetchLiveClassData();
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isRegistered ? Colors.green.shade600 : primaryColor),
                                    ),
                                  ),
                                  if (isRegistered)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Aktif & Terdaftar',
                                        style: TextStyle(color: Colors.green, fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  desc,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, height: 1.3),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Features
                              if (features.isNotEmpty) ...[
                                const Text('Materi & Fasilitas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 8),
                                ...features.map((f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(f.toString(), style: const TextStyle(fontSize: 11.5))),
                                        ],
                                      ),
                                    )),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: isRegistered
                                    ? ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedPackageId = pkg['id'];
                                            _selectedPackageName = pkg['name'];
                                          });
                                          _fetchLiveClassData();
                                        },
                                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                                        label: const Text('Masuk Jadwal Kelas ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      )
                                    : _hasLiveClassAccess && _userQuota > 0
                                        ? ElevatedButton(
                                            onPressed: () => _selectPackage(pkg['id']),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text('Pilih Paket Ini (Gunakan Kuota)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Anda belum berlangganan Live Class. Silakan lakukan Upgrade Pro terlebih dahulu.'),
                                                  backgroundColor: Colors.amber,
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.lock_outline_rounded, size: 16),
                                            label: const Text('Beli Paket / Upgrade Pro 🔒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                                              foregroundColor: isDark ? Colors.white54 : Colors.black54,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // --- 2. View: Upcoming Classes (When user is registered to a package) ---
  Widget _buildUpcomingClassesView(bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jadwal Bimbingan Live',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                    const SizedBox(width: 4),
                    Text('Bimbel Aktif', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Silakan lakukan booking jadwal kelas bimbingan yang ingin Anda ikuti di bawah ini.',
            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          
          _classes.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Belum ada jadwal kelas bimbingan saat ini.')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final lc = _classes[index];
                    final title = lc['title'] ?? 'Sesi Bimbingan';
                    final desc = lc['description'] ?? '';
                    final tutor = lc['tutor_name'] ?? 'Mentor OTWASN';
                    final startTime = lc['start_time'] ?? '';
                    final isBooked = lc['is_booked'] == true;
                    final meetLink = lc['meet_link'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54, height: 1.3),
                            ),
                          ],
                          const SizedBox(height: 12),
                          
                          // Details
                          Row(
                            children: [
                              Icon(Icons.person_rounded, size: 14, color: primaryColor),
                              const SizedBox(width: 6),
                              Text('Tutor: $tutor', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 14, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(_formatDate(startTime), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          
                          const SizedBox(height: 18),
                          
                          // Action buttons
                          Row(
                            children: [
                              if (lc['is_passed'] == true)
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Kelas Sudah Berakhir 🔒',
                                      style: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              else if (!isBooked)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _bookClass(lc['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Daftar Sesi Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                )
                              else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_rounded, color: Colors.green, size: 14),
                                      SizedBox(width: 4),
                                      Text('Terdaftar', style: TextStyle(color: Colors.green, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _joinMeeting(meetLink),
                                    icon: const Icon(Icons.videocam_rounded, size: 16),
                                    label: const Text('Masuk Kelas Zoom/Meet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
