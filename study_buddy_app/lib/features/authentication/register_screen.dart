import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllerlar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Şifre Tekrar

  // Bölüm Seçimi İçin Değişkenler
  List<dynamic> _departments = []; // API'den gelen bölümler
  String? _selectedDepartmentId; // Seçilen bölümün ID'si
  bool _isLoadingDepartments = true; // Bölümler yükleniyor mu?

  bool _isLoading = false; // Kayıt işlemi sürüyor mu?

  @override
  void initState() {
    super.initState();
    _fetchDepartments(); // Ekran açılınca bölümleri çek
  }

  // Bölümleri API'den Çekme
  Future<void> _fetchDepartments() async {
    try {
      final deps = await ApiService().getAllDepartments();
      if (mounted) {
        setState(() {
          _departments = deps;
          _isLoadingDepartments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDepartments = false);
        _showSnackBar('Bölüm listesi yüklenemedi.', Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    // 1. Boş Alan Kontrolü
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Lütfen tüm alanları doldurun.', Colors.orange);
      return;
    }

    // 2. Bölüm Seçimi Kontrolü
    if (_selectedDepartmentId == null) {
      _showSnackBar('Lütfen bölümünüzü seçin.', Colors.orange);
      return;
    }

    // 3. Şifre Eşleşme Kontrolü
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Şifreler uyuşmuyor.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kayıt İsteği
      final response = await ApiService().register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
        _selectedDepartmentId!,

        // Seçilen ID'yi gönderiyoruz
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(
          'Kayıt Başarılı! Giriş ekranına yönlendiriliyorsunuz.',
          Colors.green,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      }
    } on DioException catch (e) {
      String errorMessage = 'Kayıt başarısız.';

      // Backend'den gelen hatayı ayıklama (Parsing)
      if (e.response != null && e.response?.data is Map) {
        final data = e.response?.data;

        // 1. Durum: Validasyon hataları (Şifre kısa, Email bozuk vb.)
        if (data['errors'] != null) {
          // ASP.NET hataları genelde 'errors': { 'Password': ['...'] } şeklinde döner
          Map<String, dynamic> errors = data['errors'];
          List<String> messages = [];

          errors.forEach((key, value) {
            // value bir liste olabilir, içindeki metinleri alalım
            if (value is List) {
              messages.addAll(value.map((e) => e.toString()));
            } else {
              messages.add(value.toString());
            }
          });

          if (messages.isNotEmpty) {
            errorMessage = messages.join('\n'); // Hataları alt alta yaz
          }
        }
        // 2. Durum: Genel hatalar (Örn: Bu email kullanımda)
        else if (data['description'] != null) {
          errorMessage = data['description'];
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
      }

      // Hatayı Ekrana Pencere Olarak Basalım
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Hata Oluştu", style: TextStyle(color: Colors.red)),
          content: Text(errorMessage), // Gerçek hatayı burada göreceğiz
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    } catch (e) {
      // İnternet yoksa veya kod hatası varsa
      _showSnackBar('Beklenmeyen hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // İkon veya Başlık
            const Icon(
              Icons.app_registration,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              "Yeni Hesap Oluştur",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Ad Soyad
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Bölüm Seçimi (Dropdown)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Bölüm',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
              value: _selectedDepartmentId,
              hint: _isLoadingDepartments
                  ? const Text("Yükleniyor...")
                  : const Text("Bölüm Seçiniz"),
              items: _departments.map<DropdownMenuItem<String>>((dep) {
                // Backend'den gelen veri yapısına göre (id ve name)
                return DropdownMenuItem<String>(
                  value: dep['id'] ?? dep['_id'],
                  child: Text(
                    dep['name'] ?? dep['departmentName'] ?? 'Bilinmeyen',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDepartmentId = newValue;
                });
              },
              validator: (value) => value == null ? 'Lütfen bölüm seçin' : null,
            ),
            const SizedBox(height: 16),

            // E-posta
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Şifre
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Şifre Tekrar
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre Tekrar',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Kayıt Ol Butonu
            ElevatedButton(
              onPressed: _isLoading ? null : _registerUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kayıt Ol', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 15),

            // Giriş Yap Linki
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Login'e geri dön
              child: const Text("Zaten hesabın var mı? Giriş Yap"),
            ),
          ],
        ),
      ),
    );
  }
}
