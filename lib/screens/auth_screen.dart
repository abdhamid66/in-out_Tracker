import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Warna utama mengikuti tema aplikasi agar konsisten, namun layout sama persis dengan referensi
  final Color _primaryColor = const Color(0xFF006D5B);

  void _tampilkanPesan(String pesan) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loginDenganGoogle() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);
    
    if (user != null) {
      _tampilkanPesan('Berhasil masuk sebagai ${user.displayName ?? user.email}');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _prosesOtentikasi() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _tampilkanPesan('Semua kolom wajib diisi');
      return;
    }

    if (!_isLogin) {
      final nama = _namaController.text.trim();
      final confirm = _confirmPasswordController.text.trim();
      if (nama.isEmpty || confirm.isEmpty) {
        _tampilkanPesan('Semua kolom wajib diisi');
        return;
      }
      if (password != confirm) {
        _tampilkanPesan('Password tidak cocok');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final user = await _authService.signInWithEmailAndPassword(email, password);
        if (user != null) {
          _tampilkanPesan('Berhasil masuk!');
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      } else {
        final nama = _namaController.text.trim();
        final user = await _authService.registerWithEmailAndPassword(nama, email, password);
        if (user != null) {
          _tampilkanPesan('Berhasil daftar dan masuk!');
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _tampilkanPesan('Gagal: ${e.message}');
    } catch (e) {
      _tampilkanPesan('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool? isObscure,
    VoidCallback? onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isObscure ?? false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isObscure! ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Biru
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: _primaryColor,
            ),
            child: Column(
              children: [
                Text(
                  _isLogin ? 'Masuk ke Akun' : 'Daftar Sekarang',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin 
                    ? 'Masukkan email dan password untuk masuk'
                    : 'Buat akun untuk menyimpan data kamu',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Custom Tab (Segmented Control)
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = true),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Masuk',
                              style: TextStyle(
                                color: _isLogin ? _primaryColor : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = false),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: !_isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Daftar',
                              style: TextStyle(
                                color: !_isLogin ? _primaryColor : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Google
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _loginDenganGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isLogin ? 'Login dengan Google' : 'Daftar dengan Google',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider "atau"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('atau', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (!_isLogin)
                    _buildTextField(
                      label: 'Nama',
                      hint: 'Masukkan nama',
                      controller: _namaController,
                    ),

                  _buildTextField(
                    label: 'Email',
                    hint: 'Masukkan email',
                    controller: _emailController,
                  ),

                  _buildTextField(
                    label: 'Password',
                    hint: _isLogin ? 'Masukkan password' : 'Buat password',
                    controller: _passwordController,
                    isPassword: true,
                    isObscure: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),

                  if (!_isLogin)
                    _buildTextField(
                      label: 'Konfirmasi Password',
                      hint: 'Masukkan ulang password',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      isObscure: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),

                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Fitur lupa password
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lupa password?',
                          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),

                  SizedBox(height: _isLogin ? 20 : 30),

                  // Tombol Utama
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _prosesOtentikasi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isLogin ? 'Login' : 'Daftar',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),

                  if (!_isLogin)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5),
                          children: [
                            const TextSpan(text: 'Dengan mendaftar, kamu setuju dengan '),
                            TextSpan(text: 'Syarat & Ketentuan', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' dan\n'),
                            TextSpan(text: 'Kebijakan Privasi', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
