import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class KisiKisiScreen extends StatefulWidget {
  const KisiKisiScreen({super.key});

  @override
  State<KisiKisiScreen> createState() => _KisiKisiScreenState();
}

class _KisiKisiScreenState extends State<KisiKisiScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKisiKisi();
  }

  Future<void> _loadKisiKisi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.fetchKisiKisi();
    if (!mounted) return;

    if (data != null && data['success'] == true) {
      setState(() {
        _categories = data['categories'] as List? ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat kisi-kisi. Periksa koneksi internet Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kisi-Kisi CPNS 2026', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                        const Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: textColor, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadKisiKisi, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadKisiKisi,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _buildCategorySection(context, cat, isDark, textColor, subColor);
                    },
                  ),
                ),
    );
  }

  Widget _buildCategorySection(BuildContext context, Map<String, dynamic> cat, bool isDark, Color textColor, Color subColor) {
    final name = cat['name'] ?? 'Kategori Ujian';
    final description = cat['description'] ?? '';
    final items = cat['items'] as List? ?? [];

    Color themeColor = const Color(0xFF0284C7);
    if (name.contains('TIU')) themeColor = const Color(0xFF7C3AED);
    if (name.contains('TKP')) themeColor = const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Kategori
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),
          // Collapsible Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            itemBuilder: (context, idx) {
              final item = items[idx];
              final title = item['title'] ?? '';
              final subtitle = item['subtitle'] ?? '';

              return ExpansionTile(
                title: Text(
                  title,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor),
                ),
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: themeColor.withOpacity(0.12),
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: themeColor,
                collapsedIconColor: Colors.grey,
                childrenPadding: const EdgeInsets.only(left: 48, right: 16, bottom: 16),
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: subColor, height: 1.4),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
