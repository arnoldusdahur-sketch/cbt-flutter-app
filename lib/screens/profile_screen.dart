import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'webview_tab_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeService themeService;
  final ThemeMode currentThemeMode;
  final Color currentAccentColor;
  final void Function(ThemeMode) onThemeChanged;
  final void Function(Color) onAccentChanged;

  const ProfileScreen({
    super.key,
    required this.themeService,
    required this.currentThemeMode,
    required this.currentAccentColor,
    required this.onThemeChanged,
    required this.onAccentChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Attempt to read from cache first
    final cached = await AuthService.getCachedUser();
    if (cached != null) {
      if (mounted) {
        setState(() {
          _user = cached;
          _isLoading = false;
        });
      }
    }

    // Refresh from API
    final data = await AuthService.fetchDashboard();
    if (data != null && data.containsKey('user')) {
      if (mounted) {
        setState(() {
          _user = data['user'];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final isIOS = Platform.isIOS;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final confirm = isIOS
        ? await showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Keluar Akun'),
              content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF8E8E93))),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, true),
                  isDestructiveAction: true,
                  child: const Text('Keluar'),
                ),
              ],
            ),
          )
        : await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w700)),
              content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Batal', style: TextStyle(color: primaryColor)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );

    if (confirm == true) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onThemeChanged: widget.onThemeChanged,
            onAccentChanged: widget.onAccentChanged,
            currentThemeMode: widget.currentThemeMode,
            currentAccentColor: widget.currentAccentColor,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _openWhatsApp() async {
    final url = Uri.parse(AppConfig.whatsappSupport);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    return isIOS ? _buildIosLayout() : _buildAndroidLayout();
  }

  // ==========================================
  // iOS (Cupertino/Grouped) Layout
  // ==========================================
  Widget _buildIosLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final iosBgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final iosCardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final iosTextColor = isDark ? Colors.white : Colors.black;
    final iosSubColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final iosBorderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    final name = _user?['name'] ?? 'Peserta';
    final email = _user?['email'] ?? 'peserta@otwasn.my.id';
    final isPremium = _user?['is_premium'] == true;
    final participantId = _user?['participant_id'] ?? '-';
    final initials = _user?['initials'] ?? 'P';

    return Scaffold(
      backgroundColor: iosBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0.5,
        title: Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: iosTextColor, letterSpacing: -0.4),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Avatar & Name Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: iosCardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: primaryColor.withOpacity(0.15),
                        child: Text(
                          initials,
                          style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: iosTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 13, color: iosSubColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Premium Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPremium ? const Color(0x15059669) : Colors.black12,
                          border: Border.all(
                            color: isPremium ? const Color(0xFF059669) : Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPremium ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.person,
                              size: 14,
                              color: isPremium ? const Color(0xFF059669) : iosSubColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isPremium ? 'AKUN PREMIUM' : 'AKUN BIASA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPremium ? const Color(0xFF059669) : iosSubColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _iosSectionHeader('INFORMASI PESERTA'),

                Container(
                  decoration: BoxDecoration(
                    color: iosCardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _iosInfoRow('ID Peserta', participantId, iosTextColor, iosSubColor, iosBorderColor, false),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _iosSectionHeader('AKSI'),

                Container(
                  decoration: BoxDecoration(
                    color: iosCardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _iosActionRow(
                        title: 'Edit Profil',
                        icon: CupertinoIcons.person_crop_circle,
                        iconBg: CupertinoColors.systemBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WebViewTabScreen(
                                initialUrl: '${AppConfig.baseUrl}/profile',
                                title: 'Edit Profil',
                              ),
                            ),
                          );
                        },
                        iosTextColor: iosTextColor,
                        borderColor: iosBorderColor,
                        showDivider: true,
                      ),
                      _iosActionRow(
                        title: 'Tampilan & Tema',
                        icon: CupertinoIcons.paintbrush,
                        iconBg: CupertinoColors.systemPurple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                themeService: widget.themeService,
                                currentThemeMode: widget.currentThemeMode,
                                currentAccentColor: widget.currentAccentColor,
                                onThemeChanged: widget.onThemeChanged,
                                onAccentChanged: widget.onAccentChanged,
                              ),
                            ),
                          );
                        },
                        iosTextColor: iosTextColor,
                        borderColor: iosBorderColor,
                        showDivider: true,
                      ),
                      _iosActionRow(
                        title: 'Bantuan WhatsApp',
                        icon: CupertinoIcons.chat_bubble_2,
                        iconBg: CupertinoColors.systemGreen,
                        onTap: _openWhatsApp,
                        iosTextColor: iosTextColor,
                        borderColor: iosBorderColor,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                CupertinoButton(
                  color: const Color(0xFFFE3B30),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: _handleLogout,
                  child: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w600)),
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
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93), letterSpacing: 0.2),
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
              Text(label, style: TextStyle(fontSize: 14, color: textColor)),
              Text(value, style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w500)),
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

  Widget _iosActionRow({
    required String title,
    required IconData icon,
    required Color iconBg,
    required VoidCallback onTap,
    required Color iosTextColor,
    required Color borderColor,
    required bool showDivider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
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
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: iosTextColor),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_forward, color: Color(0xFFC7C7CC), size: 16),
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

  // ==========================================
  // Android (Material 3) Layout
  // ==========================================
  Widget _buildAndroidLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final name = _user?['name'] ?? 'Peserta';
    final email = _user?['email'] ?? 'peserta@otwasn.my.id';
    final isPremium = _user?['is_premium'] == true;
    final participantId = _user?['participant_id'] ?? '-';
    final initials = _user?['initials'] ?? 'P';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header Card
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: primaryColor.withOpacity(0.12),
                            child: Text(
                              initials,
                              style: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(fontSize: 12.5, color: subColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Premium Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPremium ? const Color(0xFFE6F4EA) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isPremium ? const Color(0xFF34A853) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPremium ? Icons.verified_rounded : Icons.account_circle_outlined,
                                  size: 15,
                                  color: isPremium ? const Color(0xFF137333) : subColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPremium ? 'AKUN PREMIUM' : 'AKUN GRATIS',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isPremium ? const Color(0xFF137333) : subColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _androidSectionLabel('Informasi Keanggotaan', subColor),
                  const SizedBox(height: 8),

                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          _androidInfoRow('ID Peserta', participantId, textColor, subColor),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _androidSectionLabel('Pilihan Aplikasi', subColor),
                  const SizedBox(height: 8),

                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _androidActionRow(
                          title: 'Ubah Data Profil',
                          subtitle: 'Edit nama, email, dan password Anda',
                          icon: Icons.person_outline_rounded,
                          iconColor: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WebViewTabScreen(
                                  initialUrl: '${AppConfig.baseUrl}/profile',
                                  title: 'Edit Profil',
                                ),
                              ),
                            );
                          },
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                        _androidActionRow(
                          title: 'Tampilan & Tema',
                          subtitle: 'Pilih warna aksen dan tema gelap/terang',
                          icon: Icons.palette_outlined,
                          iconColor: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                  themeService: widget.themeService,
                                  currentThemeMode: widget.currentThemeMode,
                                  currentAccentColor: widget.currentAccentColor,
                                  onThemeChanged: widget.onThemeChanged,
                                  onAccentChanged: widget.onAccentChanged,
                                ),
                              ),
                            );
                          },
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                        _androidActionRow(
                          title: 'Hubungi Customer Service',
                          subtitle: 'Tanya jawab dan bantuan via WhatsApp',
                          icon: Icons.support_agent_rounded,
                          iconColor: Colors.green,
                          onTap: _openWhatsApp,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _androidSectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.2),
      ),
    );
  }

  Widget _androidInfoRow(String label, String value, Color textColor, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _androidActionRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required Color textColor,
    required Color subColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: iconColor.withOpacity(0.12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: subColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subColor.withOpacity(0.7), size: 20),
          ],
        ),
      ),
    );
  }
}
