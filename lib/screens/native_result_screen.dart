import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class NativeResultScreen extends StatefulWidget {
  final int examId;
  final String examTitle;

  const NativeResultScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<NativeResultScreen> createState() => _NativeResultScreenState();
}

class _NativeResultScreenState extends State<NativeResultScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  Map<String, dynamic>? _resultData;
  bool _showDiscussion = false;
  int _discussionIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchResultData();
  }

  // Get User-Agent
  String _userAgent() {
    return 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0 Mobile Safari/537.36 ${AppConfig.userAgentSuffix}';
  }

  // Fetch result data
  Future<void> _fetchResultData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cookie = await AuthService.getSessionCookie();
      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/exams/${widget.examId}/result'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception('Gagal memuat hasil ujian.');
      }

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        if (mounted) {
          setState(() {
            _resultData = data;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(data['message'] ?? 'Gagal memproses data hasil.');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _showDiscussion ? 'Pembahasan Soal' : 'Hasil Evaluasi Tryout',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: Icon(_showDiscussion ? Icons.arrow_back_rounded : Icons.home_rounded),
          onPressed: () {
            if (_showDiscussion) {
              setState(() {
                _showDiscussion = false;
              });
            } else {
              Navigator.pop(context); // Back to dashboard
            }
          },
        ),
      ),
      body: _isLoading
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
                          onPressed: _fetchResultData,
                          child: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  ),
                )
              : _showDiscussion
                  ? _buildDiscussionView(isDark)
                  : _buildSummaryView(isDark),
    );
  }

  // --- 1. Summary View (Dashboard result) ---
  Widget _buildSummaryView(bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final score = _resultData!['score'] ?? 0;
    final maxScore = _resultData!['max_score'] ?? 550;
    final isPassed = _resultData!['passed_all_subtests'] == true;
    final subtests = _resultData!['subtests'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Congrats/Motivation)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPassed
                    ? [Colors.green.shade600, Colors.teal.shade500]
                    : [Colors.orange.shade600, Colors.red.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  isPassed ? 'MEMENUHI PASSING GRADE! 🎉' : 'BELUM MEMENUHI PASSING GRADE',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isPassed 
                      ? 'Selamat! Pertahankan pencapaian luar biasa Anda dan tingkatkan waktu pengerjaan.'
                      : 'Jangan berkecil hati! Pelajari kembali pembahasan soal di bawah untuk menambal kelemahan Anda.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Score Display
          const Text('Rincian Skor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('SKOR TOTAL', '$score', '/$maxScore', primaryColor),
                Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
                _buildStatItem('BENAR', '${_resultData!['correct_count']}', '', Colors.green),
                Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
                _buildStatItem('SALAH', '${_resultData!['incorrect_count']}', '', Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subtests Breakdown
          if (subtests.isNotEmpty) ...[
            const Text('Rincian Per Subtes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subtests.length,
              itemBuilder: (context, index) {
                final sub = subtests[index];
                final name = sub['name'] ?? '';
                final subScore = sub['score'] ?? 0;
                final subPassing = sub['passing'] ?? 0;
                final subMax = sub['max'] ?? 0;
                final isSubPassed = subScore >= subPassing;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isSubPassed ? Colors.green : Colors.red).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSubPassed ? 'Lolos PG' : 'Tidak Lolos PG',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isSubPassed ? Colors.green.shade600 : Colors.red.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress slider representation
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: subMax > 0 ? subScore / subMax : 0,
                          minHeight: 8,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
                          color: isSubPassed ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Passing Grade: $subPassing',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                          ),
                          Text(
                            'Skor Anda: $subScore / $subMax',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Discussion Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showDiscussion = true;
                  _discussionIndex = 0;
                });
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Buka Pembahasan Soal', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Kembali ke Beranda',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String suffix, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            if (suffix.isNotEmpty)
              Text(
                suffix,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
          ],
        )
      ],
    );
  }

  // --- 2. Native Discussion View ---
  Widget _buildDiscussionView(bool isDark) {
    final discussion = _resultData!['discussion'] as List<dynamic>? ?? [];
    if (discussion.isEmpty) {
      return const Center(child: Text('Tidak ada pembahasan soal yang tersedia.'));
    }

    final q = discussion[_discussionIndex];
    final questionText = q['question_text'] ?? '';
    final String? selectedAns = q['selected_answer'];
    final correctAns = q['correct_answer'] ?? '';
    final isCorrect = q['is_correct'] == true;
    final userScore = q['user_score'] ?? 0;
    final explanation = q['explanation'] ?? '';
    final scoresBreakdown = q['scores_breakdown'] as Map<String, dynamic>?;

    // Parse HTML to plain text
    final cleanQuestion = questionText.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
    final cleanExplanation = explanation.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();

    return Column(
      children: [
        // Navigation bar for questions list
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pembahasan ${_discussionIndex + 1} dari ${discussion.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              InkWell(
                onTap: () => _showDiscussionListBottomSheet(discussion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.grid_view_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      const Text('Daftar Soal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Discussion Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isCorrect ? Colors.green : (selectedAns == null ? Colors.grey : Colors.red)).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedAns == null
                            ? 'TIDAK DIJAWAB'
                            : (isCorrect ? 'JAWABAN BENAR' : 'JAWABAN SALAH'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: selectedAns == null
                              ? Colors.grey.shade600
                              : (isCorrect ? Colors.green.shade600 : Colors.red.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Skor diperoleh: $userScore',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Text
                Text(
                  cleanQuestion,
                  style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                ),
                if (q['image_url'] != null && q['image_url'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      q['image_url'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.15)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.broken_image_outlined, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Gagal memuat gambar soal.',
                                  style: TextStyle(color: Colors.red, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Options with color feedback
                _buildDiscussionOption('A', q['option_a'], selectedAns, correctAns, scoresBreakdown, isDark),
                _buildDiscussionOption('B', q['option_b'], selectedAns, correctAns, scoresBreakdown, isDark),
                _buildDiscussionOption('C', q['option_c'], selectedAns, correctAns, scoresBreakdown, isDark),
                _buildDiscussionOption('D', q['option_d'], selectedAns, correctAns, scoresBreakdown, isDark),
                _buildDiscussionOption('E', q['option_e'], selectedAns, correctAns, scoresBreakdown, isDark),

                const SizedBox(height: 24),
                // Explanation Card (Pembahasan)
                const Text('Pembahasan & Kunci Jawaban', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Kunci Jawaban: ${correctAns.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cleanExplanation,
                        style: const TextStyle(fontSize: 12.5, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Navigation Footer
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _discussionIndex > 0
                    ? () {
                        setState(() {
                          _discussionIndex--;
                        });
                      }
                    : null,
                child: const Text('Sebelumnya'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showDiscussion = false;
                  });
                },
                child: const Text('Selesai Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: _discussionIndex < discussion.length - 1
                    ? () {
                        setState(() {
                          _discussionIndex++;
                        });
                      }
                    : null,
                child: const Text('Selanjutnya'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionOption(
    String label,
    String? content,
    String? selectedAns,
    String correctAns,
    Map<String, dynamic>? scoresBreakdown,
    bool isDark,
  ) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    final cleanContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final optionKey = label.toLowerCase();
    
    final isSelected = selectedAns == optionKey;
    final isCorrectOption = correctAns == optionKey;

    Color boxColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    Color labelBgColor = isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    Color labelTextColor = isDark ? Colors.white70 : Colors.black87;

    // TKP: Multiple scores, no single correct option in traditional sense
    final isTkp = scoresBreakdown != null;
    final tkpScore = isTkp ? (scoresBreakdown[optionKey] ?? 0) : 0;

    if (isTkp) {
      if (isSelected) {
        boxColor = Colors.purple.withOpacity(0.08);
        borderColor = Colors.purple;
        labelBgColor = Colors.purple;
        labelTextColor = Colors.white;
      }
    } else {
      if (isCorrectOption) {
        boxColor = Colors.green.withOpacity(0.08);
        borderColor = Colors.green;
        labelBgColor = Colors.green;
        labelTextColor = Colors.white;
      } else if (isSelected) {
        boxColor = Colors.red.withOpacity(0.08);
        borderColor = Colors.red;
        labelBgColor = Colors.red;
        labelTextColor = Colors.white;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: (isSelected || isCorrectOption) ? 1.6 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(shape: BoxShape.circle, color: labelBgColor),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, color: labelTextColor, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cleanContent,
                style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (isTkp) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('+$tkpScore', style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Open discussion sheet navigation
  void _showDiscussionListBottomSheet(List<dynamic> discussion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Pembahasan Soal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: discussion.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, idx) {
                    final q = discussion[idx];
                    final isCurrent = _discussionIndex == idx;
                    final isCorrect = q['is_correct'] == true;
                    final isUnanswered = q['selected_answer'] == null;

                    Color boxColor = Colors.red;
                    Color labelColor = Colors.red.shade700;
                    if (isUnanswered) {
                      boxColor = Colors.grey.shade400;
                      labelColor = Colors.grey.shade700;
                    } else if (isCorrect) {
                      boxColor = Colors.green;
                      labelColor = Colors.green.shade700;
                    }

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _discussionIndex = idx;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: boxColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isCurrent ? Theme.of(context).colorScheme.primary : boxColor, width: isCurrent ? 2.5 : 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
