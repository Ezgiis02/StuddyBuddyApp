// lib/features/authentication/login_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form alanlarını kontrol etmek için Controller'lar
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Yüklenme durumunu yönetmek için

  // İpucu: Android için 10.0.2.2 kullanıyoruz.
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api/auth/login';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Giriş İşlemi Fonksiyonu
  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Lütfen e-posta ve şifrenizi girin.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Giriş Başarılı
        // İleride token'ı burada SharedPreferences ile güvenli bir şekilde saklayacağız.
        // final String token = responseBody['token'];
        final String token = responseBody['token'];

        // 🔑 Token'ı yerel depolamaya kaydetme
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', token); // jwtToken adıyla kaydedildi!
        _showSnackBar(
          'Giriş başarılı! Ana sayfaya yönlendiriliyorsunuz.',
          Colors.green,
        );
        // Başarılı girişten sonra Home sayfasına yönlendir
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Giriş Başarısız (Örn: Hatalı şifre/e-posta)
        _showSnackBar(
          responseBody['message'] ?? 'Giriş başarısız oldu. Kontrol edin.',
          Colors.red,
        );
      }
    } catch (e) {
      // Sunucuya ulaşılamama veya ağ hatası
      _showSnackBar(
        'Hata: Sunucuya ulaşılamıyor. API sunucunuz çalışıyor mu?',
        Colors.red,
      );
      print('HTTP Hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Basit Uyarı (Snackbar) Gösterme Fonksiyonu
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
      appBar: AppBar(title: const Text('StudyBuddy Giriş'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Tekrar Hoş Geldiniz!',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.05),

            // E-posta Giriş Alanı - CONTROLLER EKLENDİ
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
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
                labelText: 'Şifre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 32.0),

            // Giriş Butonu - API İŞLEMİ BURADA
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _loginUser, // Yükleniyorsa devre dışı
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Giriş Yap', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 24.0),

            // Kayıt Ol Butonu
            TextButton(
              onPressed: () {
                // Kayıt Ol sayfasına yönlendir
                Navigator.of(context).pushNamed('/register');
              },
              child: const Text('Hesabınız yok mu? Kayıt Olun'),
            ),
          ],
        ),
      ),
    );
  }
}
