import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCachedUser();
    if (!mounted) return;

    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _addressController.text = user['address'] ?? '';
      setState(() => _isLoading = false);
    } else {
      // Fallback: fetch dashboard to cache user
      final data = await AuthService.fetchDashboard();
      if (!mounted) return;
      
      if (data != null && data.containsKey('user')) {
        _nameController.text = data['user']['name'] ?? '';
        _emailController.text = data['user']['email'] ?? '';
        _phoneController.text = data['user']['phone'] ?? '';
        _addressController.text = data['user']['address'] ?? '';
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat profil Anda.';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();

    final response = await AuthService.updateProfile(
      name,
      email,
      phone: phone.isNotEmpty ? phone : null,
      address: address.isNotEmpty ? address : null,
      password: password.isNotEmpty ? password : null,
    );
    if (!mounted) return;

    if (response != null && response['success'] == true) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil Anda berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Pop back with success result
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = response?['message'] ?? 'Gagal memperbarui profil. Periksa koneksi atau email Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sunting Profil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Placeholder
                    Center(
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: primaryColor.withOpacity(0.12),
                        child: Icon(Icons.person_rounded, size: 40, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Input Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          Text(
                            'Nama Lengkap',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: textColor, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama lengkap',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Nama tidak boleh kosong';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          Text(
                            'Alamat Email',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: textColor, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Masukkan alamat email',
                              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Email tidak boleh kosong';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                return 'Masukkan email yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Phone Field
                          Text(
                            'Nomor Telepon',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: textColor, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nomor telepon',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (!RegExp(r'^[0-9+\-\s]{8,20}$').hasMatch(val.trim())) {
                                  return 'Masukkan nomor telepon yang valid';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Address Field
                          Text(
                            'Alamat Lengkap',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            keyboardType: TextInputType.multiline,
                            maxLines: 3,
                            style: TextStyle(color: textColor, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Masukkan alamat lengkap Anda',
                              prefixIcon: const Icon(Icons.home_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Row(
                            children: [
                              Text(
                                'Password Baru',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(Kosongkan jika tidak diubah)',
                                style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(color: textColor, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Masukkan password baru',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            validator: (val) {
                              if (val != null && val.isNotEmpty && val.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
