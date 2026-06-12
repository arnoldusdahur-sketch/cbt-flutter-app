import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'webview_tab_screen.dart';
import 'tryout_list_screen.dart';
import 'ebooks_screen.dart';
import 'capaian_screen.dart';
import 'kisi_kisi_screen.dart';
import 'live_class_screen.dart';
import 'upgrade_screen.dart';
import 'native_exam_screen.dart';
import 'native_live_class_screen.dart';
import 'native_result_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int) onTabRequest; // Callback to request tab switch in MainShell if needed

  const DashboardScreen({
    super.key,
    required this.onTabRequest,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _statsVisible = true;
  late final PageController _pageController;
  int _currentBannerIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadDashboardData();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
        _startBannerTimer();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.fetchDashboard();
    if (!mounted) return;

    if (data != null) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } else {
      // Try to load cached user if offline/API fails
      final cachedUser = await AuthService.getCachedUser();
      if (cachedUser != null) {
        setState(() {
          _dashboardData = {
            'user': cachedUser,
            'stats': {'completed_count': 0, 'average_score': 0, 'passing_percentage': 0, 'user_rank': 0},
            'exams': [],
            'leaderboard': []
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data. Periksa koneksi internet Anda.';
        });
      }
    }
  }

  List<dynamic> _filterExams(List<dynamic> exams) {
    if (_searchQuery.isEmpty) return exams;
    return exams.where((exam) {
      final title = (exam['title'] ?? '').toString().toLowerCase();
      final bankName = (exam['bank_name'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) || bankName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null && _dashboardData == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboardData,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _dashboardData?['user'] ?? {};
    final stats = _dashboardData?['stats'] ?? {};
    final exams = _dashboardData?['exams'] as List? ?? [];
    final leaderboard = _dashboardData?['leaderboard'] as List? ?? [];

    final initials = user['initials'] ?? 'P';
    final name = user['name'] ?? 'Peserta';
    final isPremium = user['is_premium'] == true;
    final participantId = user['participant_id'] ?? '-';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Background Melengkung Gradien Hijau Emerald BKN
          _buildGradientHeaderBg(context, isDark),

          // 2. Konten Scrollable utama di depan
          RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sapaan profil (posisi transparan)
                  _buildHeaderContent(context, isDark, initials, name, isPremium, participantId),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3. Overlapping Card (Stats + Grid 1 Menu Cepat)
                        _buildOverlappingMainCard(context, stats, isDark),

                        const SizedBox(height: 20),

                        // 4. Banner Carousel Slider
                        _buildBannersCarousel(context, isDark),

                        const SizedBox(height: 20),

                        // 5. Search Bar
                        _buildSearchBox(context, isDark),

                        const SizedBox(height: 20),

                        // 6. Menu Grid Bagian 2 (Layanan Lainnya)
                        _buildMenuGrid2(context, isDark),

                        const SizedBox(height: 20),

                        // 7. Tryout / Ujian Aktif (Terfilter)
                        _buildActiveExamsSection(context, _filterExams(exams), isDark, primaryColor, textColor, subColor),

                        const SizedBox(height: 20),

                        // 8. Leaderboard Top 5
                        _buildLeaderboardSection(context, leaderboard, isDark, primaryColor, textColor, subColor),

                        const SizedBox(height: 20),

                        // 9. Countdown CPNS
                        _buildCountdownTimer(context, isDark),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Background melengkung gradien
  Widget _buildGradientHeaderBg(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 205,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF02AB6C), const Color(0xFF007A48)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
    );
  }

  // 2. Header sapaan
  Widget _buildHeaderContent(BuildContext context, bool isDark, String initials, String name, bool isPremium, String participantId) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final greeting = _getGreeting();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isPremium
                    ? [Colors.amber.shade400, Colors.amber.shade700]
                    : [Colors.white70, Colors.white38],
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Text(
                initials,
                style: TextStyle(
                  color: isPremium ? Colors.amber.shade700 : (isDark ? Colors.white : primaryColor),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Premium Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPremium ? Colors.amber.withOpacity(0.3) : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPremium ? 'PRO' : 'FREE',
                        style: TextStyle(
                          color: isPremium ? Colors.amber.shade300 : Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $participantId',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Help Center Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WebViewTabScreen(
                    initialUrl: AppConfig.whatsappSupport,
                    title: 'Pusat Bantuan',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Hubungi Bantuan',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // 3. Overlapping Card
  Widget _buildOverlappingMainCard(BuildContext context, Map<String, dynamic> stats, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNestedStatsCard(context, stats, isDark),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
          const SizedBox(height: 16),
          _buildMenuRowGrid1(context, isDark),
        ],
      ),
    );
  }

  // Nested Stats Card
  Widget _buildNestedStatsCard(BuildContext context, Map<String, dynamic> stats, bool isDark) {
    final completed = stats['completed_count'] ?? 0;
    final average = stats['average_score'] ?? 0;
    final passing = stats['passing_percentage'] ?? 0;
    final rank = stats['user_rank'] ?? 0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF334155), const Color(0xFF1E293B)]
              : [const Color(0xFF02AB6C), const Color(0xFF007A48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rata-rata Skor Tryout',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _statsVisible = !_statsVisible;
                  });
                },
                child: Icon(
                  _statsVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _statsVisible ? '$average' : '••••••',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
               const SizedBox(width: 8),
              if (_statsVisible)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rank > 0 ? 'Peringkat #$rank' : 'Belum Ada Peringkat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_statsVisible) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (average / 500).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.15),
                color: average >= 311 ? const Color(0xFF10B981) : Colors.amber,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tryout Selesai',
                    style: TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _statsVisible ? '$completed' : '••',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelulusan PG',
                    style: TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _statsVisible ? '$passing%' : '••',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CapaianScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rapor', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 8),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Row menu cepat horizontal (Grid 1)
  Widget _buildMenuRowGrid1(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMenuItem(context, 'Tryout SKD', Icons.edit_document, Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TryoutListScreen(initialCategory: 'skd')));
        }, isDark),
        _buildMenuItem(context, 'SKB Dosen', Icons.school, Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TryoutListScreen(initialCategory: 'skb_dosen')));
        }, isDark),
        _buildMenuItem(context, 'E-Book', Icons.menu_book, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EbooksScreen()));
        }, isDark),
        _buildMenuItem(context, 'Kisi-Kisi', Icons.assignment_outlined, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const KisiKisiScreen()));
        }, isDark),
      ],
    );
  }

  // Menu Grid 2
  Widget _buildMenuGrid2(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Lainnya',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            _buildMenuItem(context, 'Materi', Icons.info_outline, Colors.indigo, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WebViewTabScreen(
                    initialUrl: '${AppConfig.baseUrl}/informations',
                    title: 'Materi Belajar',
                  ),
                ),
              );
            }, isDark),
            _buildMenuItem(context, 'Rapor Hasil', Icons.leaderboard, Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CapaianScreen()));
            }, isDark),
            _buildMenuItem(context, 'Live Class', Icons.video_camera_front, Colors.red, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NativeLiveClassScreen(),
                ),
              );
            }, isDark),
            _buildMenuItem(context, 'Upgrade Pro', Icons.star_rounded, Colors.amber, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
            }, isDark),
          ],
        ),
      ],
    );
  }

  // Generic menu item
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Banners Carousel
  Widget _buildBannersCarousel(BuildContext context, bool isDark) {
    final banners = [
      _buildBannerItem(
        context,
        'Tips Lulus SKD CPNS 2026',
        'Pelajari trik pengerjaan TIU, TWK, & TKP lebih cepat.',
        [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
        Icons.lightbulb_outline_rounded,
      ),
      _buildBannerItem(
        context,
        'Akses 100+ Soal & Pembahasan',
        'Upgrade ke paket PRO untuk akses simulasi ujian lengkap.',
        [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
        Icons.star_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WebViewTabScreen(
                initialUrl: '${AppConfig.baseUrl}/upgrade',
                title: 'Upgrade Pro',
              ),
            ),
          );
        },
      ),
      _buildBannerItem(
        context,
        'Bimbingan Live Class Mingguan',
        'Ikuti pembahasan soal interaktif bersama tutor berpengalaman.',
        [const Color(0xFFD97706), const Color(0xFFF59E0B)],
        Icons.video_camera_front_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NativeLiveClassScreen(),
            ),
          );
        },
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 105,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemCount: banners.length,
            itemBuilder: (context, index) => banners[index],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => Container(
              width: _currentBannerIndex == index ? 12 : 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: _currentBannerIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerItem(
    BuildContext context,
    String title,
    String description,
    List<Color> colors,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 9.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: Colors.white.withOpacity(0.35),
              size: 44,
            ),
          ],
        ),
      ),
    );
  }

  // Search Box
  Widget _buildSearchBox(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          fontSize: 13,
        ),
        decoration: InputDecoration(
          icon: Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 20,
          ),
          hintText: 'Cari simulasi ujian...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontSize: 13,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Active Exams Section
  Widget _buildActiveExamsSection(BuildContext context, List exams, bool isDark, Color primaryColor, Color textColor, Color subColor) {
    if (exams.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulasi Ujian Aktif',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Ujian dengan kata kunci "${_searchQuery}" tidak ditemukan.',
                  style: TextStyle(fontSize: 11, color: subColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simulasi Ujian Aktif',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              return _buildExamCard(context, exam, isDark, primaryColor, textColor, subColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam, bool isDark, Color primaryColor, Color textColor, Color subColor) {
    final title = exam['title'] ?? 'Simulasi Ujian';
    final bankName = exam['bank_name'] ?? 'Kombinasi';
    final questionCount = exam['question_count'] ?? 110;
    final duration = exam['duration_minutes'] ?? 100;
    final isPremium = exam['is_premium'] == true;
    final hasAccess = exam['has_access'] == true;
    final sessionStatus = exam['session_status'];
    final examId = exam['id'];

    String btnText = 'Kerjakan';
    Color btnColor = primaryColor;
    String actionUrl = '${AppConfig.baseUrl}/exams/$examId/start/mobile';

    if (!hasAccess) {
      btnText = 'Beli Paket 🔒';
      btnColor = Colors.amber.shade700;
      actionUrl = '${AppConfig.baseUrl}/upgrade?exam_id=$examId';
    } else if (sessionStatus == 'ongoing') {
      btnText = 'Lanjutkan';
      btnColor = Colors.orange;
      actionUrl = '${AppConfig.baseUrl}/exams/$examId/take';
    } else if (sessionStatus == 'completed') {
      btnText = 'Ulangi Ujian';
      btnColor = primaryColor;
      actionUrl = '${AppConfig.baseUrl}/exams/$examId/start/mobile';
    }

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      bankName,
                      style: const TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text('PRO', style: TextStyle(color: Colors.amber, fontSize: 7, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 10, color: subColor),
                  const SizedBox(width: 2),
                  Text('$questionCount soal', style: TextStyle(fontSize: 8.5, color: subColor)),
                  const SizedBox(width: 8),
                  Icon(Icons.timer_outlined, size: 10, color: subColor),
                  const SizedBox(width: 2),
                  Text('${duration}m', style: TextStyle(fontSize: 8.5, color: subColor)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () {
                      if (hasAccess) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NativeExamScreen(examId: examId, examTitle: title),
                          ),
                        ).then((_) => _loadDashboardData());
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WebViewTabScreen(initialUrl: actionUrl, title: title),
                          ),
                        ).then((_) => _loadDashboardData());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      btnText,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              if (sessionStatus == 'completed') ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NativeResultScreen(examId: examId, examTitle: title),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_rounded, size: 14),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Leaderboard Section
  Widget _buildLeaderboardSection(BuildContext context, List leaderboard, bool isDark, Color primaryColor, Color textColor, Color subColor) {
    if (leaderboard.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peringkat Nasional Teratas',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboard.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final rank = entry['rank'] ?? (index + 1);
                final name = entry['name'] ?? 'Peserta';
                final initials = entry['initials'] ?? '??';
                final score = entry['avg_score'] ?? 0;
                final isCurrent = entry['is_current_user'] == true;

                Color rankBg = Colors.grey.withOpacity(0.1);
                Color rankText = subColor;
                if (rank == 1) {
                  rankBg = Colors.amber.withOpacity(0.2);
                  rankText = Colors.amber.shade800;
                } else if (rank == 2) {
                  rankBg = Colors.blueGrey.withOpacity(0.2);
                  rankText = Colors.blueGrey.shade700;
                } else if (rank == 3) {
                  rankBg = Colors.deepOrange.withOpacity(0.15);
                  rankText = Colors.deepOrange.shade800;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: isCurrent ? primaryColor.withOpacity(0.08) : Colors.transparent,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: rankBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rankText),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: (isCurrent ? primaryColor : subColor).withOpacity(0.15),
                        child: Text(
                          initials,
                          style: TextStyle(color: isCurrent ? primaryColor : subColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Countdown Widget
  Widget _buildCountdownTimer(BuildContext context, bool isDark) {
    final targetDate = DateTime(2026, 10, 1);
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final daysRemaining = difference.isNegative ? 0 : difference.inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COUNTDOWN CPNS 2026',
                    style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Siapkan diri Anda dari sekarang!',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$daysRemaining Hari Lagi',
              style: const TextStyle(
                color: Color(0xFFD97706),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
