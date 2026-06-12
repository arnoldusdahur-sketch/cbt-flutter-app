import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'native_result_screen.dart';

class CapaianScreen extends StatefulWidget {
  const CapaianScreen({super.key});

  @override
  State<CapaianScreen> createState() => _CapaianScreenState();
}

class _CapaianScreenState extends State<CapaianScreen> {
  Map<String, dynamic>? _capaianData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCapaian();
  }

  Future<void> _loadCapaian() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.fetchCapaian();
    if (!mounted) return;

    if (data != null && data['success'] == true) {
      setState(() {
        _capaianData = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat rapor belajar. Periksa koneksi internet Anda.';
      });
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rapor Capaian', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: textColor, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadCapaian, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCapaian,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Dashboard Ringkasan
                        _buildSummaryDashboard(context, isDark, primaryColor, textColor, subColor),
                        
                        const SizedBox(height: 20),
                        
                        // 2. Breakdown Skor TWK/TIU/TKP
                        _buildBreakdownGrid(context, isDark, textColor, subColor),

                        const SizedBox(height: 24),

                        // 3. Header Riwayat
                        Text(
                          'Riwayat Simulasi Ujian',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 12),

                        // 4. List Riwayat
                        _buildHistoryList(context, isDark, primaryColor, textColor, subColor),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryDashboard(BuildContext context, bool isDark, Color primaryColor, Color textColor, Color subColor) {
    final stats = _capaianData?['stats'] ?? {};
    final completed = stats['completed_count'] ?? 0;
    final average = stats['average_score'] ?? 0;
    final maxScore = stats['max_score'] ?? 0;
    final passingPct = stats['passing_percentage'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress for Passing Percentage
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: passingPct / 100,
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  color: const Color(0xFF10B981),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$passingPct%',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Lulus PG',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Stats Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Tryout Selesai', '$completed', Colors.blue),
                const SizedBox(height: 10),
                _buildStatRow('Nilai Rata-rata', '$average', primaryColor),
                const SizedBox(height: 10),
                _buildStatRow('Skor Tertinggi', '$maxScore', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownGrid(BuildContext context, bool isDark, Color textColor, Color subColor) {
    final stats = _capaianData?['stats'] ?? {};
    final twk = stats['avg_twk'] ?? 0;
    final tiu = stats['avg_tiu'] ?? 0;
    final tkp = stats['avg_tkp'] ?? 0;

    return Row(
      children: [
        Expanded(child: _buildBreakdownCard('TWK', '$twk / 150', 'PG: 65', const Color(0xFF0284C7), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildBreakdownCard('TIU', '$tiu / 175', 'PG: 80', const Color(0xFF7C3AED), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildBreakdownCard('TKP', '$tkp / 225', 'PG: 166', const Color(0xFFD97706), isDark)),
      ],
    );
  }

  Widget _buildBreakdownCard(String category, String value, String passingInfo, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              category,
              style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            passingInfo,
            style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, bool isDark, Color primaryColor, Color textColor, Color subColor) {
    final history = _capaianData?['history'] as List? ?? [];

    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 36, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              'Belum ada riwayat simulasi yang diselesaikan.',
              style: TextStyle(color: subColor, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final session = history[index];
        final title = session['exam_title'] ?? 'Simulasi Ujian';
        final score = session['score'] ?? 0;
        final twk = session['twk_score'] ?? 0;
        final tiu = session['tiu_score'] ?? 0;
        final tkp = session['tkp_score'] ?? 0;
        final isPassed = session['is_passed'] == true;
        final dateStr = _formatDate(session['end_time']);
        final examId = session['exam_id'];

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPassed ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPassed ? 'LULUS PG' : 'TIDAK LULUS PG',
                      style: TextStyle(
                        color: isPassed ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateStr, style: TextStyle(color: subColor, fontSize: 9.5)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildHistoryMetric('TWK', twk, const Color(0xFF0284C7)),
                      const SizedBox(width: 10),
                      _buildHistoryMetric('TIU', tiu, const Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      _buildHistoryMetric('TKP', tkp, const Color(0xFFD97706)),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Skor', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                          Text(
                            '$score',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primaryColor),
                          ),
                        ],
                      ),
                      if (examId != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NativeResultScreen(
                                  examId: examId,
                                  examTitle: title,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                            minimumSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryMetric(String label, int val, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Text(
          '$val',
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
