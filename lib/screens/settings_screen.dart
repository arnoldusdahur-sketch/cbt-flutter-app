import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../config/app_config.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;
  final ThemeMode currentThemeMode;
  final Color currentAccentColor;
  final void Function(ThemeMode) onThemeChanged;
  final void Function(Color) onAccentChanged;

  const SettingsScreen({
    super.key,
    required this.themeService,
    required this.currentThemeMode,
    required this.currentAccentColor,
    required this.onThemeChanged,
    required this.onAccentChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _selectedMode;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentThemeMode;
    _selectedColor = widget.currentAccentColor;
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    return isIOS ? _buildIosLayout(context) : _buildAndroidLayout(context);
  }

  // ==========================================
  // iOS (Cupertino/Grouped) Layout
  // ==========================================
  Widget _buildIosLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    // Standard iOS Settings Colors
    final iosBgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final iosCardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final iosTextColor = isDark ? Colors.white : Colors.black;
    final iosSubColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final iosBorderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: iosBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0.5,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        title: Text(
          'Tampilan',
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 17, 
            color: iosTextColor,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24, color: primaryColor),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Selesai',
              style: TextStyle(
                color: primaryColor, 
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // iOS Section Label
          _iosSectionHeader('MODE TAMPILAN'),
          
          // iOS Grouped List
          Container(
            decoration: BoxDecoration(
              color: iosCardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _iosThemeRow(
                  title: 'Otomatis',
                  subtitle: 'Ikuti tema sistem iPhone',
                  icon: CupertinoIcons.device_phone_portrait,
                  iconBg: CupertinoColors.systemOrange,
                  value: ThemeMode.system,
                  iosTextColor: iosTextColor,
                  iosSubColor: iosSubColor,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  borderColor: iosBorderColor,
                  showDivider: true,
                ),
                _iosThemeRow(
                  title: 'Terang',
                  subtitle: 'Tampilan bersih & cerah',
                  icon: CupertinoIcons.sun_max_fill,
                  iconBg: CupertinoColors.systemYellow,
                  value: ThemeMode.light,
                  iosTextColor: iosTextColor,
                  iosSubColor: iosSubColor,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  borderColor: iosBorderColor,
                  showDivider: true,
                ),
                _iosThemeRow(
                  title: 'Gelap',
                  subtitle: 'Hemat baterai & nyaman di mata',
                  icon: CupertinoIcons.moon_fill,
                  iconBg: CupertinoColors.systemPurple,
                  value: ThemeMode.dark,
                  iosTextColor: iosTextColor,
                  iosSubColor: iosSubColor,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  borderColor: iosBorderColor,
                  showDivider: false,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _iosSectionHeader('WARNA AKSEN'),
          
          // iOS Color Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iosCardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah warna penekanan utama aplikasi:',
                  style: TextStyle(fontSize: 13, color: iosSubColor),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: AppTheme.accentPresets.map((preset) {
                      final color = preset['color'] as Color;
                      final isSelected = _selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = color);
                          widget.onAccentChanged(color);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 48 : 40,
                          height: isSelected ? 48 : 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  CupertinoIcons.checkmark, 
                                  color: Colors.white, 
                                  size: isSelected ? 20 : 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _iosSectionHeader('INFORMASI'),
          
          // iOS Info Group
          Container(
            decoration: BoxDecoration(
              color: iosCardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _iosInfoRow('Versi Aplikasi', '${AppConfig.appVersion} (${AppConfig.appVersionCode})', iosTextColor, iosSubColor, iosBorderColor, true),
                _iosInfoRow('Platform', 'Flutter (iOS Native)', iosTextColor, iosSubColor, iosBorderColor, true),
                _iosInfoRow('Pengembang', 'Tim OTWASN', iosTextColor, iosSubColor, iosBorderColor, false),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _iosSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5, 
          fontWeight: FontWeight.w500, 
          color: Color(0xFF8E8E93), 
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _iosThemeRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required ThemeMode value,
    required Color iosTextColor,
    required Color iosSubColor,
    required Color primaryColor,
    required bool isDark,
    required Color borderColor,
    required bool showDivider,
  }) {
    final isSelected = _selectedMode == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMode = value);
        widget.onThemeChanged(value);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                // iOS Styled Colored Icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: TextStyle(
                          fontSize: 15, 
                          fontWeight: FontWeight.w500, 
                          color: iosTextColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle, 
                        style: TextStyle(
                          fontSize: 11.5, 
                          color: iosSubColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(CupertinoIcons.checkmark_alt, color: primaryColor, size: 22),
              ],
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 12),
                child: Container(height: 0.5, color: borderColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iosInfoRow(String label, String value, Color textColor, Color subColor, Color borderColor, bool showDivider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w400)),
              Text(value, style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w400)),
            ],
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(height: 0.5, color: borderColor),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // Android (Material 3) Layout
  // ==========================================
  Widget _buildAndroidLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Pengaturan Tampilan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('SELESAI', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: primaryColor.withOpacity(0.15),
                  ),
                  child: Icon(Icons.palette_outlined, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kustomisasi Tampilan', style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: textColor)),
                      const SizedBox(height: 3),
                      Text('Sesuaikan tema dan warna sesuai selera Anda',
                          style: TextStyle(fontSize: 12, color: subColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===== TEMA SECTION =====
          _sectionLabel('🌙 Mode Tampilan', subColor),
          const SizedBox(height: 8),

          Card(
            color: cardColor,
            child: Column(
              children: [
                _androidThemeOption(
                  context: context,
                  title: 'Mode Sistem',
                  subtitle: 'Ikuti pengaturan sistem',
                  icon: Icons.phone_android_rounded,
                  value: ThemeMode.system,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                _androidThemeOption(
                  context: context,
                  title: 'Mode Terang',
                  subtitle: 'Latar belakang putih/cerah',
                  icon: Icons.light_mode_rounded,
                  value: ThemeMode.light,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                _androidThemeOption(
                  context: context,
                  title: 'Mode Gelap',
                  subtitle: 'Latar belakang hitam/gelap',
                  icon: Icons.dark_mode_rounded,
                  value: ThemeMode.dark,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===== ACCENT COLOR SECTION =====
          _sectionLabel('🎨 Warna Aksen', subColor),
          const SizedBox(height: 8),

          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih warna utama aplikasi:',
                      style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppTheme.accentPresets.map((preset) {
                      final color = preset['color'] as Color;
                      final name = preset['name'] as String;
                      final isSelected = _selectedColor.value == color.value;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = color);
                          widget.onAccentChanged(color);
                        },
                        child: Tooltip(
                          message: name,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 52 : 44,
                            height: isSelected ? 52 : 44,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : Border.all(color: Colors.transparent),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 16, spreadRadius: 2)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ===== APP INFO SECTION =====
          _sectionLabel('ℹ️ Informasi Aplikasi', subColor),
          const SizedBox(height: 8),

          Card(
            color: cardColor,
            child: Column(
              children: [
                _androidInfoRow('Versi Aplikasi', '${AppConfig.appVersion} (${AppConfig.appVersionCode})', textColor, subColor),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                _androidInfoRow('Platform', 'Flutter (Android Native)', textColor, subColor),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                _androidInfoRow('Developer', 'Tim OTWASN', textColor, subColor),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: color, letterSpacing: 0.04));
  }

  Widget _androidThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode value,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color subColor,
  }) {
    final isSelected = _selectedMode == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedMode = value);
        widget.onThemeChanged(value);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isSelected ? primaryColor.withOpacity(0.15) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
              ),
              child: Icon(icon, color: isSelected ? primaryColor : subColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: subColor)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _androidInfoRow(String label, String value, Color textColor, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.5, color: subColor, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13.5, color: textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
