import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/user.dart';
import '../../core/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller'lar
  late TextEditingController _nameController;
  late TextEditingController
  _locationTextController; // Tercih edilen yerler (Metin)

  // Şehir / İlçe Listeleri ve Seçimleri
  List<String> _cities = []; // API'den gelecek şehirler
  List<String> _districts = []; // Seçilen şehrin ilçeleri
  String? _selectedCity; // Seçili Şehir
  String? _selectedDistrict; // Seçili İlçe
  bool _isLoadingCities = true; // Yükleme durumu

  // Resim Seçimi
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Mevcut Kullanıcı Bilgilerini Form Alanlarına Doldur
    _nameController = TextEditingController(text: widget.currentUser.name);
    _locationTextController = TextEditingController(
      text: widget.currentUser.preferredLocationsText ?? "",
    );

    _selectedCity = widget.currentUser.city;
    _selectedDistrict = widget.currentUser.district;

    // 2. Sayfa Açılınca Şehir Listesini Çek
    _loadCities();
  }

  // Şehirleri API'den Çek
  Future<void> _loadCities() async {
    var cities = await ApiService().getCities();

    if (mounted) {
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });

      // Eğer kullanıcının veritabanında kayıtlı bir şehri varsa
      // ve bu şehir API'den gelen listede mevcutsa:
      if (_selectedCity != null && _cities.contains(_selectedCity)) {
        // HEMAN İLÇELERİ YÜKLE Kİ DROPDOWN BOŞ KALMASIN
        await _loadDistricts(_selectedCity!);

        // İlçeler yüklendikten sonra seçili ilçeyi tekrar set et
        // (Bazen ilçe listesi yüklenirken dropdown sıfırlanabilir, bunu garantiye alıyoruz)
        if (mounted && widget.currentUser.district != null) {
          setState(() {
            _selectedDistrict = widget.currentUser.district;
          });
        }
      }
    }
  }

  // Seçilen Şehrin İlçelerini API'den Çek
  Future<void> _loadDistricts(String cityName) async {
    // Yeni şehir seçilince eski ilçeleri temizle
    setState(() {
      _districts = [];
      // Şehir değiştiyse, eski ilçe seçimini kaldır (Uyuşmazlık olmasın)
      if (_selectedCity != widget.currentUser.city) {
        _selectedDistrict = null;
      }
    });

    // API İsteği
    var districts = await ApiService().getDistricts(cityName);

    if (mounted) {
      setState(() {
        _districts = districts;

        // Eğer seçili ilçe yeni listede yoksa seçimi kaldır
        if (_selectedDistrict != null &&
            !_districts.contains(_selectedDistrict)) {
          _selectedDistrict = null;
        }
      });
    }
  }

  // Galeriden Resim Seçme
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // --- GÜNCELLENEN KAYDETME İŞLEMİ ---
  Future<void> _saveProfile() async {
    if (_selectedCity == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen şehir ve ilçe seçiniz.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ARTIK 3 PARAMETRE GÖNDERİYORUZ
    bool success = await ApiService().updateLocation(
      _selectedCity!,
      _selectedDistrict!,
      _locationTextController.text, // Text alanındaki veriyi de ekledik
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bilgiler başarıyla güncellendi!"),
            backgroundColor: Colors.green,
          ),
        );
        // İstersen burada Navigator.pop yapma, kullanıcı görsün güncel halini.
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Güncelleme başarısız.")));
      }
    }
  }

  // Şifre Değiştirme Penceresi
  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Şifre Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mevcut Şifre"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Yeni Şifre"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await ApiService().changePassword(
                currentPassCtrl.text,
                newPassCtrl.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? "Şifre değişti!" : "Hata: Eski şifre yanlış.",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Değiştir"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Profil resmi: Yeni seçilen > Web URL > Default İkon
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (widget.currentUser.profileImageUrl != null) {
      imageProvider = NetworkImage(widget.currentUser.profileImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profili Düzenle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- 1. RESİM ALANI ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. AD SOYAD ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Ad Soyad",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val!.isEmpty ? "Ad boş olamaz" : null,
              ),
              const SizedBox(height: 15),

              // --- 3. ŞEHİR SEÇİMİ (Cascade Dropdown) ---
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(
                  labelText: "Şehir",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                hint: _isLoadingCities
                    ? const Text("Yükleniyor...")
                    : const Text("Şehir Seçiniz"),
                items: _cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCity = val;
                    _selectedDistrict = null; // Şehir değişince ilçe sıfırlanır
                    _districts = []; // Liste temizlenir
                  });
                  // Seçilen şehrin ilçelerini API'den iste
                  if (val != null) _loadDistricts(val);
                },
                validator: (val) => val == null ? "Lütfen şehir seçin" : null,
              ),
              const SizedBox(height: 15),

              // --- 4. İLÇE SEÇİMİ ---
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                  labelText: "İlçe",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                hint: _selectedCity == null
                    ? const Text("Önce şehir seçin")
                    : (_districts.isEmpty
                          ? const Text("Yükleniyor...")
                          : const Text("İlçe Seçiniz")),
                // Şehir seçilmeden burası aktif olmaz
                items: _districts.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: _selectedCity == null
                    ? null
                    : (val) => setState(() => _selectedDistrict = val),
              ),
              const SizedBox(height: 15),

              // --- 5. TERCİH EDİLEN YERLER ---
              TextFormField(
                controller: _locationTextController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Tercih Ettiğin Çalışma Yerleri",
                  hintText: "Örn: Kızılay Starbucks, Milli Kütüphane...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 20),

              // --- 6. KAYDET BUTONU ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Değişiklikleri Kaydet",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // --- 7. ŞİFRE DEĞİŞTİRME BUTONU ---
              TextButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_reset, color: Colors.red),
                label: const Text(
                  "Şifre Değiştir",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
