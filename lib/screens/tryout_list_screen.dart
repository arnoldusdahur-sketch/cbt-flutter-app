import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'webview_tab_screen.dart';
import 'native_exam_screen.dart';
import 'native_result_screen.dart';

class TryoutListScreen extends StatefulWidget {
  final String initialCategory; // 'skd' or 'skb_dosen'

  const TryoutListScreen({
    super.key,
    this.initialCategory = 'skd',
  });

  @override
  State<TryoutListScreen> createState() => _TryoutListScreenState();
}

class _TryoutListScreenState extends State<TryoutListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialCategory == 'skb_dosen' ? 1 : 0,
    );
    _loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
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
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat daftar ujian. Periksa koneksi internet Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daftar Tryout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
          tabs: const [
            Tab(text: 'SKD CPNS 2026'),
            Tab(text: 'SKB DOSEN BKN'),
          ],
        ),
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
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: textColor, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadExams, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExamList(context, 'skd', isDark, primaryColor, textColor),
                    _buildExamList(context, 'skb_dosen', isDark, primaryColor, textColor),
                  ],
                ),
    );
  }

  Widget _buildExamList(BuildContext context, String category, bool isDark, Color primaryColor, Color textColor) {
    final list = _dashboardData?['exams'] as List? ?? [];
    final user = _dashboardData?['user'] ?? {};
    final isPremiumUser = user['is_premium'] == true;

    // Filter exams based on category.
    // In our DB: SKB Dosen category has bank_name containing "skb" or "dosen", or Category in Laravel model.
    // Let's filter by matching titles/categories if possible.
    final filtered = list.where((exam) {
      final bankName = (exam['bank_name'] ?? '').toString().toLowerCase();
      final title = (exam['title'] ?? '').toString().toLowerCase();
      final isSkb = bankName.contains('skb') || bankName.contains('dosen') || title.contains('skb') || title.contains('dosen');
      return category == 'skb_dosen' ? isSkb : !isSkb;
    }).toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadExams,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Text(
              'Belum ada simulasi ujian aktif.',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final exam = filtered[index];
          return _buildExamCard(context, exam, isDark, primaryColor, textColor, isPremiumUser);
        },
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam, bool isDark, Color primaryColor, Color textColor, bool isPremiumUser) {
    final title = exam['title'] ?? 'Simulasi Ujian';
    final bankName = exam['bank_name'] ?? 'Kombinasi';
    final questionCount = exam['question_count'] ?? 110;
    final duration = exam['duration_minutes'] ?? 100;
    final isPremiumExam = exam['is_premium'] == true;
    final hasAccess = exam['has_access'] == true;
    final sessionStatus = exam['session_status'];
    final examId = exam['id'];
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPremiumExam ? Colors.amber.withOpacity(0.12) : Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPremiumExam ? 'PRO' : 'GRATIS',
                  style: TextStyle(
                    color: isPremiumExam ? Colors.amber.shade700 : Colors.blue.shade700,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (sessionStatus == 'completed')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(color: Colors.green, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            bankName,
            style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.description_outlined, size: 13, color: subColor),
              const SizedBox(width: 4),
              Text('$questionCount Soal', style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 13, color: subColor),
              const SizedBox(width: 4),
              Text('${duration} Menit', style: TextStyle(fontSize: 11, color: subColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      if (hasAccess) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NativeExamScreen(examId: examId, examTitle: title),
                          ),
                        ).then((_) => _loadExams());
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WebViewTabScreen(initialUrl: actionUrl, title: title),
                          ),
                        ).then((_) => _loadExams());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              if (sessionStatus == 'completed') ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  height: 42,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NativeResultScreen(examId: examId, examTitle: title),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
