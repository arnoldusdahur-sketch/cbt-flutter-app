import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  List<dynamic> _informations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInformations();
  }

  Future<void> _loadInformations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.fetchInformations();
    if (!mounted) return;

    if (data != null && data['success'] == true) {
      setState(() {
        _informations = data['informations'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat informasi. Silakan periksa koneksi internet Anda.';
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
        title: const Text('Informasi Terbaru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
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
                        const Icon(Icons.info_outline_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: TextStyle(color: textColor, fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadInformations, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : _informations.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada informasi terbaru saat ini.',
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInformations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _informations.length,
                        itemBuilder: (context, index) {
                          final info = _informations[index];
                          return _buildInfoCard(context, info, isDark, textColor, subColor);
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Map<String, dynamic> info, bool isDark, Color textColor, Color subColor) {
    final title = info['title'] ?? 'Informasi';
    final category = info['category'] ?? 'Umum';
    final content = info['content'] ?? '';
    final date = info['created_at'] ?? '';
    final imageUrl = info['image_url'];

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InformationDetailScreen(info: info),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => buildInformationBannerPlaceholder(category, Theme.of(context).colorScheme.primary, height: 150.0),
                    )
                  : buildInformationBannerPlaceholder(category, Theme.of(context).colorScheme.primary, height: 150.0),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(color: subColor, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 12,
                      color: subColor,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InformationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> info;

  const InformationDetailScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final title = info['title'] ?? 'Informasi';
    final category = info['category'] ?? 'Umum';
    final content = info['content'] ?? '';
    final date = info['created_at'] ?? '';
    final imageUrl = info['image_url'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Informasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => buildInformationBannerPlaceholder(category, Theme.of(context).colorScheme.primary, height: 220.0),
                  )
                : buildInformationBannerPlaceholder(category, Theme.of(context).colorScheme.primary, height: 220.0),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(color: subColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? Colors.white12 : Colors.black12),
                  const SizedBox(height: 16),
                  ...parseHtmlToWidgets(content, isDark, Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget to render category-specific fallback banners when no image is uploaded
Widget buildInformationBannerPlaceholder(String category, Color primaryColor, {double height = 160.0}) {
  Color bg = const Color(0xFF0F172A);
  IconData icon = Icons.info_outline_rounded;
  
  if (category == 'Tips & Trik') {
    bg = const Color(0xFF0284C7);
    icon = Icons.lightbulb_outline_rounded;
  } else if (category == 'Info Penting') {
    bg = const Color(0xFFD97706);
    icon = Icons.warning_amber_rounded;
  } else if (category == 'Event') {
    bg = const Color(0xFF7C3AED);
    icon = Icons.event_note_rounded;
  }

  return Container(
    width: double.infinity,
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [bg, bg.withOpacity(0.85)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: height > 180 ? 44 : 34, color: Colors.white54),
        const SizedBox(height: 8),
        Text(
          category.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: height > 180 ? 11 : 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ],
    ),
  );
}

// Helper function to parse basic HTML content into structured native Flutter widgets
List<Widget> parseHtmlToWidgets(String htmlContent, bool isDark, Color primaryColor) {
  final List<Widget> widgets = [];
  final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
  
  String cleaned = htmlContent
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&ndash;', '—')
      .replaceAll('&ldquo;', '“')
      .replaceAll('&rdquo;', '”')
      .replaceAll('&middot;', '•');
      
  final blocks = cleaned.split(RegExp(r'(?=<(?:p|h\d|ul|ol|table|blockquote|li)\b)'));
  
  bool isInOrderedList = false;
  int orderedListIndex = 1;
  
  for (var block in blocks) {
    block = block.trim();
    if (block.isEmpty) continue;
    
    // Check list state change
    if (block.contains('<ol')) {
      isInOrderedList = true;
      orderedListIndex = 1;
    }
    if (block.contains('</ol>')) {
      isInOrderedList = false;
    }
    if (block.contains('<ul')) {
      isInOrderedList = false;
    }
    
    if (block.startsWith(RegExp(r'<h[1-4]'))) {
      final text = block.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (text.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ));
      }
    } else if (block.startsWith('<li')) {
      // Remove li tags but keep inline formatting tags for inline parsing
      final innerHtml = block.replaceAll(RegExp(r'<\/?li[^>]*>'), '').trim();
      if (innerHtml.isNotEmpty) {
        final prefix = isInOrderedList ? '$orderedListIndex. ' : '• ';
        if (isInOrderedList) {
          orderedListIndex++;
        }
        
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prefix, style: TextStyle(fontSize: 12.5, color: primaryColor, fontWeight: FontWeight.bold)),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textColor.withOpacity(0.85),
                      height: 1.4,
                    ),
                    children: _parseInlineHtml(innerHtml, isDark, primaryColor, textColor),
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    } else if (block.startsWith('<table') || block.contains('<tr')) {
      final rowMatches = RegExp(r'<tr[^>]*>(.*?)<\/tr>', dotAll: true).allMatches(block);
      final List<List<String>> tableData = [];
      for (final rowMatch in rowMatches) {
        final rowContent = rowMatch.group(1) ?? '';
        final colMatches = RegExp(r'<t[dh][^>]*>(.*?)<\/t[dh]>', dotAll: true).allMatches(rowContent);
        final List<String> columns = [];
        for (final colMatch in colMatches) {
          final cellText = colMatch.group(1) ?? '';
          columns.add(cellText.replaceAll(RegExp(r'<[^>]*>'), '').trim());
        }
        if (columns.isNotEmpty) {
          tableData.add(columns);
        }
      }
      
      if (tableData.isNotEmpty) {
        // Find max columns
        int maxCols = 0;
        for (final row in tableData) {
          if (row.length > maxCols) {
            maxCols = row.length;
          }
        }
        
        // Dynamic column widths
        final Map<int, TableColumnWidth> colWidths = {};
        for (int i = 0; i < maxCols; i++) {
          colWidths[i] = const FlexColumnWidth(1.0);
        }
        
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.8),
                ),
                columnWidths: colWidths,
                children: tableData.asMap().entries.map((entry) {
                  final rowIndex = entry.key;
                  final row = entry.value;
                  final isHeader = rowIndex == 0;
                  
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isHeader 
                          ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04))
                          : null,
                    ),
                    children: List.generate(maxCols, (colIndex) {
                      final cellText = colIndex < row.length ? row[colIndex] : '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          cellText,
                          style: TextStyle(
                            fontSize: isHeader ? 11 : 11.5,
                            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                            color: isHeader ? primaryColor : textColor,
                          ),
                        ),
                      );
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
        ));
      }
    } else {
      // It's a paragraph or regular block. Remove enclosing p tags but keep inner content for inline formatting
      final innerHtml = block.replaceAll(RegExp(r'<\/?p[^>]*>'), '').trim();
      if (innerHtml.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.5,
                color: textColor.withOpacity(0.85),
                height: 1.45,
              ),
              children: _parseInlineHtml(innerHtml, isDark, primaryColor, textColor),
            ),
          ),
        ));
      }
    }
  }
  return widgets;
}

// Inline HTML parser for tags: strong, b, em, i, u
List<InlineSpan> _parseInlineHtml(String text, bool isDark, Color primaryColor, Color textColor) {
  final List<InlineSpan> spans = [];
  final tagExp = RegExp(r'<[^>]+>');
  int lastMatchEnd = 0;
  
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  
  final matches = tagExp.allMatches(text);
  for (final match in matches) {
    if (match.start > lastMatchEnd) {
      final plainText = text.substring(lastMatchEnd, match.start);
      spans.add(TextSpan(
        text: plainText,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
          color: textColor.withOpacity(0.85),
        ),
      ));
    }
    
    final tag = match.group(0)!.toLowerCase();
    if (tag.startsWith('<strong') || tag.startsWith('<b')) {
      isBold = true;
    } else if (tag.startsWith('</strong') || tag.startsWith('</b')) {
      isBold = false;
    } else if (tag.startsWith('<em') || tag.startsWith('<i')) {
      isItalic = true;
    } else if (tag.startsWith('</em') || tag.startsWith('</i')) {
      isItalic = false;
    } else if (tag.startsWith('<u')) {
      isUnderline = true;
    } else if (tag.startsWith('</u>')) {
      isUnderline = false;
    }
    
    lastMatchEnd = match.end;
  }
  
  if (lastMatchEnd < text.length) {
    final plainText = text.substring(lastMatchEnd);
    spans.add(TextSpan(
      text: plainText,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
        color: textColor.withOpacity(0.85),
      ),
    ));
  }
  
  return spans;
}
