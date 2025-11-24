// lib/features/authentication/register_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON verilerini işlemek için

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Form alanlarını kontrol etmek için Controller'lar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Yüklenme durumunu yönetmek için

  // İpucu: IP adresinizi kullanın. localhost, emülatörün kendisini temsil eder!
  // Eğer Android emülatör kullanıyorsanız 10.0.2.2 kullanın.
  // Eğer iOS simülatör kullanıyorsanız 127.0.0.1 kullanın.
  // Eğer fiziksel cihaz kullanıyorsanız, bilgisayarınızın yerel IP adresini kullanın.
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api/auth/register';

  @override
  void dispose() {
    // Hafıza sızıntısını önlemek için controller'ları temizliyoruz
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. Kayıt İşlemi Fonksiyonu
  Future<void> _registerUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      // Basit bir uyarı (ileride daha profesyonel validation yapacağız)
      _showSnackBar('Lütfen tüm alanları doldurun.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true; // Yükleniyor durumunu başlat
    });

    try {
      final response = await http.post(
        Uri.parse(_apiBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Kayıt Başarılı
        _showSnackBar(
          'Kayıt Başarılı! Şimdi Giriş yapabilirsiniz.',
          Colors.green,
        );
        // Başarılı kayıttan sonra giriş ekranına yönlendir
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        // Kayıt Başarısız (Örn: E-posta zaten kullanılıyor)
        _showSnackBar(
          responseBody['message'] ?? 'Kayıt başarısız oldu.',
          Colors.red,
        );
      }
    } catch (e) {
      // Sunucuya ulaşılamama veya ağ hatası
      _showSnackBar('Hata: Sunucuya ulaşılamıyor.', Colors.red);
      print('HTTP Hatası: $e');
    } finally {
      setState(() {
        _isLoading = false; // Yükleniyor durumunu bitir
      });
    }
  }

  // 3. Basit Uyarı (Snackbar) Gösterme Fonksiyonu
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Hesap Oluştur'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'StudyBuddy Ailesine Katılın!',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.05),

            // Ad Soyad Giriş Alanı - CONTROLLER EKLENDİ
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Adınız ve Soyadınız',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16.0),

            // E-posta Giriş Alanı - CONTROLLER EKLENDİ
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Üniversite E-postası',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),

            // Şifre Giriş Alanı - CONTROLLER EKLENDİ
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre (En az 6 karakter)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 32.0),

            // Kayıt Ol Butonu - API İŞLEMİ BURADA
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _registerUser, // Yükleniyorsa devre dışı
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Kayıt Ol', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 24.0),

            // Giriş Yap Butonu
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              child: const Text('Zaten hesabınız var mı? Giriş Yapın'),
            ),
          ],
        ),
      ),
    );
  }
}
