import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'native_result_screen.dart';

class NativeExamScreen extends StatefulWidget {
  final int examId;
  final String examTitle;

  const NativeExamScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<NativeExamScreen> createState() => _NativeExamScreenState();
}

class _NativeExamScreenState extends State<NativeExamScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  late PageController _pageController;
  late ScrollController _scrollController;
  
  int _timeRemainingSeconds = 0;
  Timer? _timer;
  
  bool _isSavingAnswer = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _scrollController = ScrollController();
    _startOrResumeExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Get User-Agent
  String _userAgent() {
    return 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0 Mobile Safari/537.36 ${AppConfig.userAgentSuffix}';
  }

  // Fetch or resume session
  Future<void> _startOrResumeExam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cookie = await AuthService.getSessionCookie();
      
      // Step 1: Start exam session
      final startResp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/exams/${widget.examId}/start'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (startResp.statusCode != 200) {
        final data = jsonDecode(startResp.body);
        throw Exception(data['message'] ?? 'Gagal memulai ujian.');
      }

      // Step 2: Fetch questions details
      final questionsResp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/exams/${widget.examId}/questions'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (questionsResp.statusCode != 200) {
        throw Exception('Gagal memuat daftar soal.');
      }

      final qData = jsonDecode(questionsResp.body);
      if (qData['success'] == true) {
        if (mounted) {
          setState(() {
            _questions = qData['questions'] ?? [];
            _timeRemainingSeconds = qData['time_remaining_seconds'] ?? 0;
            _isLoading = false;
          });
          _startTimer();
        }
      } else {
        throw Exception(qData['message'] ?? 'Gagal mengambil data soal.');
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

  // Timer runner
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemainingSeconds > 0) {
            _timeRemainingSeconds--;
          } else {
            _timer?.cancel();
            _autoFinishExam();
          }
        });
      }
    });
  }

  // Format time remaining
  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hStr = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    return '$hStr$mStr:$sStr';
  }

  // Save answer to server
  Future<void> _saveAnswer(int questionId, String? answer, bool isDoubtful) async {
    setState(() {
      _isSavingAnswer = true;
    });

    try {
      final cookie = await AuthService.getSessionCookie();
      final resp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/exams/${widget.examId}/answer'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'question_id': questionId,
          'answer': answer,
          'is_doubtful': isDoubtful,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          // Update local state
          setState(() {
            final idx = _questions.indexWhere((q) => q['id'] == questionId);
            if (idx != -1) {
              _questions[idx]['selected_answer'] = answer;
              _questions[idx]['is_doubtful'] = isDoubtful;
            }
          });
        }
      }
    } catch (_) {
      // Fail silently, retry on next click or connection status
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAnswer = false;
        });
      }
    }
  }

  // Finish exam manually
  Future<void> _finishExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Selesaikan Ujian?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin menyelesaikan ujian ini? Pastikan semua jawaban sudah terisi dengan benar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    _submitFinishRequest();
  }

  // Auto finish when time is up
  void _autoFinishExam() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return const AlertDialog(
          title: Text('Waktu Habis!'),
          content: Text('Waktu ujian Anda telah berakhir. Sistem akan menyimpan dan mengirimkan jawaban Anda secara otomatis.'),
        );
      },
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _submitFinishRequest();
      }
    });
  }

  Future<void> _submitFinishRequest() async {
    setState(() {
      _isLoading = true;
    });
    _timer?.cancel();

    try {
      final cookie = await AuthService.getSessionCookie();
      final resp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/mobile/exams/${widget.examId}/finish'),
        headers: {
          'User-Agent': _userAgent(),
          'Cookie': cookie,
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => NativeResultScreen(examId: widget.examId, examTitle: widget.examTitle),
            ),
          );
        }
      } else {
        throw Exception('Gagal menyimpan hasil akhir ujian.');
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

  // Confirmation on exit
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Ujian?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Waktu ujian akan tetap berjalan meskipun Anda keluar dari layar ini. Yakin ingin kembali?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return shouldExit == true;
  }

  // Define subtest properties
  Map<String, dynamic> _getSubtestTheme(String type) {
    final cleanType = type.toLowerCase();
    if (cleanType == 'twk') {
      return {
        'name': 'Tes Wawasan Kebangsaan (TWK)',
        'color': Colors.red.shade700,
        'bgColor': const Color(0xFFFEF2F2),
        'darkBgColor': const Color(0xFF451A1A),
      };
    } else if (cleanType == 'tiu') {
      return {
        'name': 'Tes Inteligensia Umum (TIU)',
        'color': Colors.teal.shade700,
        'bgColor': const Color(0xFFF0FDFA),
        'darkBgColor': const Color(0xFF0F3B37),
      };
    } else if (cleanType == 'tkp') {
      return {
        'name': 'Tes Karakteristik Pribadi (TKP)',
        'color': Colors.purple.shade700,
        'bgColor': const Color(0xFFFAF5FF),
        'darkBgColor': const Color(0xFF3B1F54),
      };
    } else if (cleanType == 'etika_tridharma') {
      return {
        'name': 'Etika & Tri Dharma Perguruan Tinggi',
        'color': Colors.indigo.shade700,
        'bgColor': const Color(0xFFEEF2FF),
        'darkBgColor': const Color(0xFF1E224F),
      };
    } else if (cleanType == 'literasi_inggris') {
      return {
        'name': 'Literasi Bahasa Inggris',
        'color': Colors.blue.shade700,
        'bgColor': const Color(0xFFEFF6FF),
        'darkBgColor': const Color(0xFF1E2B4F),
      };
    } else if (cleanType == 'penalaran_masalah') {
      return {
        'name': 'Penalaran & Pemecahan Masalah',
        'color': Colors.orange.shade800,
        'bgColor': const Color(0xFFFFF7ED),
        'darkBgColor': const Color(0xFF4F2B1E),
      };
    } else if (cleanType == 'dimensi_psikologi') {
      return {
        'name': 'Dimensi Psikologi',
        'color': Colors.pink.shade700,
        'bgColor': const Color(0xFFFDF2F8),
        'darkBgColor': const Color(0xFF4F1E38),
      };
    } else {
      return {
        'name': 'Materi Ujian',
        'color': Colors.grey.shade700,
        'bgColor': const Color(0xFFF8FAFC),
        'darkBgColor': const Color(0xFF1E293B),
      };
    }
  }

  // Horizontal numbers row navigation (instantly scrollable)
  Widget _buildHorizontalNavigation(Color primaryColor, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              itemBuilder: (context, idx) {
                final q = _questions[idx];
                final isCurrent = _currentIndex == idx;
                final hasAns = q['selected_answer'] != null;
                final isDoubt = q['is_doubtful'] == true;

                Color boxColor;
                Color textColor;
                Color borderColor = Colors.transparent;

                // Curated premium HSL-tailored colors matching website
                if (hasAns) {
                  if (isDoubt) {
                    boxColor = Colors.amber.shade600;
                    textColor = Colors.white;
                  } else {
                    boxColor = Colors.green.shade600;
                    textColor = Colors.white;
                  }
                } else {
                  if (isDoubt) {
                    boxColor = Colors.amber.shade300;
                    textColor = Colors.black87;
                  } else {
                    // Unanswered: Soft rose background with dark red text
                    boxColor = isDark ? const Color(0xFF5C1D24) : const Color(0xFFFEE2E2);
                    textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444);
                    borderColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5);
                  }
                }

                if (isCurrent) {
                  borderColor = primaryColor;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      _pageController.jumpToPage(idx);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: primaryColor, width: 2)
                            : (borderColor != Colors.transparent ? Border.all(color: borderColor, width: 1) : null),
                        boxShadow: isCurrent
                            ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 4)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Trigger side drawer
          Builder(
            builder: (context) => InkWell(
              onTap: () {
                Scaffold.of(context).openEndDrawer();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300, width: 0.5),
                ),
                child: const Icon(Icons.grid_view_rounded, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Website-style navigation drawer
  Widget _buildEndDrawer(BuildContext context, Color primaryColor, bool isDark) {
    int answeredCount = _questions.where((q) => q['selected_answer'] != null && q['is_doubtful'] != true).length;
    int doubtCount = _questions.where((q) => q['is_doubtful'] == true).length;
    int emptyCount = _questions.length - answeredCount - doubtCount;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Peta Soal Ujian',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Statistics matching web legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatLegend(Colors.green.shade600, '$answeredCount', 'Terisi', isDark),
                  _buildStatLegend(Colors.amber.shade600, '$doubtCount', 'Ragu', isDark),
                  _buildStatLegend(Colors.red, '$emptyCount', 'Kosong', isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Question Grid
              Expanded(
                child: GridView.builder(
                  itemCount: _questions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, idx) {
                    final q = _questions[idx];
                    final isCurrent = _currentIndex == idx;
                    final hasAns = q['selected_answer'] != null;
                    final isDoubt = q['is_doubtful'] == true;

                    Color boxColor;
                    Color textColor;
                    Color borderColor = Colors.transparent;

                    if (hasAns) {
                      if (isDoubt) {
                        boxColor = Colors.amber.shade600;
                        textColor = Colors.white;
                      } else {
                        boxColor = Colors.green.shade600;
                        textColor = Colors.white;
                      }
                    } else {
                      if (isDoubt) {
                        boxColor = Colors.amber.shade300;
                        textColor = Colors.black87;
                      } else {
                        boxColor = isDark ? const Color(0xFF5C1D24) : const Color(0xFFFEE2E2);
                        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444);
                        borderColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5);
                      }
                    }

                    if (isCurrent) {
                      borderColor = primaryColor;
                    }

                    return InkWell(
                      onTap: () {
                        _pageController.jumpToPage(idx);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(color: primaryColor, width: 2)
                              : (borderColor != Colors.transparent ? Border.all(color: borderColor, width: 1) : null),
                          boxShadow: isCurrent
                              ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 4)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Selesaikan Ujian button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // close drawer
                  _finishExam();
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Selesaikan Ujian', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatLegend(Color color, String count, String label, bool isDark) {
    Color boxColor = color;
    Color textColor = Colors.white;
    if (color == Colors.red) {
      boxColor = isDark ? const Color(0xFF5C1D24) : const Color(0xFFFEE2E2);
      textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444);
    }
    return Column(
      children: [
        Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(6),
            border: color == Colors.red ? Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            count,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        endDrawer: _isLoading || _errorMessage != null ? null : _buildEndDrawer(context, primaryColor, isDark),
        appBar: AppBar(
          title: Text(widget.examTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
          actions: [
            // Timer displays in app bar
            if (!_isLoading && _errorMessage == null)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: _timeRemainingSeconds < 300 ? Colors.red : primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_timeRemainingSeconds),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _timeRemainingSeconds < 300 ? Colors.red : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
                            onPressed: _startOrResumeExam,
                            child: const Text('Coba Lagi'),
                          )
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Progress Bar
                      LinearProgressIndicator(
                        value: _questions.isNotEmpty ? (_currentIndex + 1) / _questions.length : 0,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                        color: primaryColor,
                        minHeight: 3,
                      ),

                      // Horizontal Navigation Scrollable bar
                      _buildHorizontalNavigation(primaryColor, isDark),

                      // Questions list using PageView
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _questions.length,
                          onPageChanged: (idx) {
                            setState(() {
                              _currentIndex = idx;
                            });
                            if (_scrollController.hasClients) {
                              double offset = idx * 38.0; // 32 box width + 6 margin
                              double screenWidth = MediaQuery.of(context).size.width;
                              double targetOffset = offset - (screenWidth / 2) + 19;
                              _scrollController.animateTo(
                                targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          itemBuilder: (context, idx) {
                            final q = _questions[idx];
                            return _buildQuestionItem(q, isDark, primaryColor);
                          },
                        ),
                      ),

                      // Bottom actions bar
                      _buildBottomActions(primaryColor, isDark),
                    ],
                  ),
      ),
    );
  }

  Widget _buildQuestionItem(Map<String, dynamic> q, bool isDark, Color primaryColor) {
    final questionText = q['question_text'] ?? '';
    final String? selectedAns = q['selected_answer'];
    final type = q['type'] ?? 'other';
    final theme = _getSubtestTheme(type);

    // Parse and remove clean HTML formatting falls or tags
    final cleanText = questionText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question card container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? theme['darkBgColor'] : theme['bgColor'],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                    ? (theme['color'] as Color).withOpacity(0.3)
                    : (theme['color'] as Color).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtest badge inside
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (theme['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (theme['name'] as String).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: theme['color'] as Color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      'SOAL NO. ${_currentIndex + 1}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Question image if available
                if (q['image_url'] != null && q['image_url'].toString().isNotEmpty) ...[
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
                  const SizedBox(height: 12),
                ],

                // Question text
                Text(
                  cleanText,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Options A-E
          _buildOptionItem('A', q['option_a'], selectedAns == 'a', q, primaryColor, isDark),
          _buildOptionItem('B', q['option_b'], selectedAns == 'b', q, primaryColor, isDark),
          _buildOptionItem('C', q['option_c'], selectedAns == 'c', q, primaryColor, isDark),
          _buildOptionItem('D', q['option_d'], selectedAns == 'd', q, primaryColor, isDark),
          _buildOptionItem('E', q['option_e'], selectedAns == 'e', q, primaryColor, isDark),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
    String label,
    String? content,
    bool isSelected,
    Map<String, dynamic> q,
    Color primaryColor,
    bool isDark,
  ) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    final cleanContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isSavingAnswer
            ? null
            : () {
                _saveAnswer(q['id'], isSelected ? null : label.toLowerCase(), q['is_doubtful'] == true);
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.06)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circle key option
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                  border: isSelected ? null : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Option content
              Expanded(
                child: Text(
                  cleanContent,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(Color primaryColor, bool isDark) {
    final q = _questions[_currentIndex];
    final isDoubt = q['is_doubtful'] == true;
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Prev Button
            IconButton(
              onPressed: _currentIndex > 0
                  ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 8),

            // Doubt toggle (Ragu-ragu)
            Expanded(
              child: InkWell(
                onTap: _isSavingAnswer
                    ? null
                    : () {
                        _saveAnswer(q['id'], q['selected_answer'], !isDoubt);
                      },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDoubt 
                        ? Colors.amber.withOpacity(0.12)
                        : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                    border: isDoubt ? Border.all(color: Colors.amber, width: 1.5) : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDoubt ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: isDoubt ? Colors.amber : (isDark ? Colors.white60 : Colors.black54),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ragu-Ragu',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDoubt ? Colors.amber.shade900 : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Next / Finish Button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finishExam();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? Colors.red.shade600 : primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isLast ? 'Selesai Ujian' : 'Selanjutnya',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
