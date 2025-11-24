// lib/features/matching/matching_screen.dart (SON FİLTRELEME VE İŞLEV)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  // Profil filtresi için mevcut kullanıcı verisi (pending, incoming, favorites listelerini içerir)
  Map<String, dynamic>? _currentUser;

  List<dynamic> _matchedUsers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final String _matchingApiUrl = 'http://10.0.2.2:3000/api/users/matches';
  final String _sendRequestUrl = 'http://10.0.2.2:3000/api/users/send-request';
  final String _rateUrl = 'http://10.0.2.2:3000/api/users/rate';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // Profil filtresi için çekilmeli
  }

  // Token yardımcı fonksiyonu
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  // Profil verisini çeken fonksiyon (Filtreleme için gerekli)
  Future<void> _loadCurrentUser() async {
    final token = await _getToken();

    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/auth/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _currentUser = jsonDecode(response.body)['user'];
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- API ÇAĞRI FONKSİYONLARI ---

  // 1. API'den eşleşmeleri çeken fonksiyon (Butona Bağlı)
  Future<void> _fetchMatches() async {
    final token = await _getToken();
    if (token == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    if (_currentUser == null) {
      await _loadCurrentUser();
      if (_currentUser == null) {
        _showSnackBar('Profil yüklenemedi. Tekrar deneyin.', Colors.red);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _matchedUsers = [];
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(_matchingApiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        setState(() {
          _matchedUsers = responseBody['matches'];
          _isLoading = false;
        });

        if (_matchedUsers.isEmpty) {
          _showSnackBar('Yeni eşleşme bulunamadı.', Colors.blueGrey);
        }
      } else if (response.statusCode == 401) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() {
          _errorMessage =
              jsonDecode(response.body)['message'] ??
              'Eşleşme yüklenirken bir sorun oluştu.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: API sunucunuz çalışıyor mu?';
        _isLoading = false;
        print('Matching HTTP Hatası: $e');
      });
    }
  }

  // 2. Puanlama API'sine gönderme fonksiyonu
  Future<void> _rateUser(String targetUserId, double rating) async {
    final token = await _getToken();
    if (token == null) return;

    _showSnackBar('Puan kaydediliyor...', Colors.grey);

    try {
      final response = await http.put(
        Uri.parse(_rateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'targetUserId': targetUserId, 'newRating': rating}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        _showSnackBar(
          'Puanlama başarılı! Yeni Ortalama: ${responseBody['newAvgRating']}',
          Colors.green,
        );
        await _fetchMatches();
      } else {
        final responseBody = jsonDecode(response.body);
        _showSnackBar(
          responseBody['message'] ?? 'Puanlama başarısız oldu.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Bağlantı hatası: Puanlama yapılamadı.', Colors.red);
    }
  }

  // 3. Çalışma İsteği Gönderme Fonksiyonu
  Future<void> _sendRequest(String targetUserId, String targetUserName) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse(_sendRequestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'targetUserId': targetUserId}),
      );

      if (response.statusCode == 200) {
        _showSnackBar(
          '$targetUserName kişisine istek gönderildi!',
          Colors.green,
        );
        // Liste ve profil filtresini yenile
        await _loadCurrentUser();
        await _fetchMatches();
      } else {
        final responseBody = jsonDecode(response.body);
        _showSnackBar(
          responseBody['message'] ?? 'İstek gönderme başarısız.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Bağlantı hatası: İstek gönderilemedi.', Colors.red);
    }
  }

  // Puanlama penceresi (Slider içerir)
  void _showRatingDialog(
    BuildContext context,
    String targetName,
    String targetId,
  ) {
    double _currentRating = 3.0; // Varsayılan puan

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$targetName Puanla'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Puanınız: ${_currentRating.toStringAsFixed(1)} / 5.0'),
                  const SizedBox(height: 10),
                  Slider(
                    value: _currentRating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: _currentRating.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        _currentRating = value;
                      });
                    },
                  ),
                  const Text('Not: Puan, ortalama puanı etkileyecektir.'),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Puanı Kaydet'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _rateUser(targetId, _currentRating);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // YENİ ARKADAŞ BUL BUTONU
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchMatches,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Icon(Icons.search),
            label: Text(
              _isLoading ? 'Aranıyor...' : 'Yeni Arkadaş Bul',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),

        // Eşleşme Sonuçları
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }

    // Yükleniyor veya profil verisi bekleniyorsa
    if (_currentUser == null && !_isLoading) {
      return const Center(child: Text('Profil verisi yükleniyor...'));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 🔥 🔥 🔥 KRİTİK FİLTRELEME 🔥 🔥 🔥
    // API'den gelen objeleri (populate edilmiş) ID'lerine çevirerek filtre listesi oluşturma
    // Bu, önceki hatayı çözen güvenli okuma yöntemidir.
    final List pendingRaw =
        _currentUser!['pendingRequests'] as List<dynamic>? ?? [];
    final List incomingRaw =
        _currentUser!['incomingRequests'] as List<dynamic>? ?? [];
    final List favoritesRaw =
        _currentUser!['favorites'] as List<dynamic>? ?? [];

    // Listeleri, objelerin içindeki '_id' alanlarını kullanarak string ID listesine çevirme
    // (Populate edilmiş obje ya da sadece string ID gelme ihtimaline karşı güvenli dönüşüm)

    final List incomingIDs = incomingRaw.map((e) {
      if (e is Map) {
        return e['_id'] as String? ?? '';
      }
      // Eğer Map değilse, ID'nin string olarak geldiğini varsayıyoruz.
      return e as String? ?? '';
    }).toList();

    final List pendingIDs = pendingRaw.map((e) {
      if (e is Map) {
        return e['_id'] as String? ?? '';
      }
      return e as String? ?? '';
    }).toList();

    final List favoritesIDs = favoritesRaw.map((e) {
      if (e is Map) {
        return e['_id'] as String? ?? '';
      }
      return e as String? ?? '';
    }).toList();

    // Eşleşme listesini filtrele
    final filtered = _matchedUsers.where((u) {
      final id = u['_id'];

      // Halihazırda etkileşime girilen kişileri listeden hariç tut
      return !pendingIDs.contains(id) &&
          !incomingIDs.contains(id) &&
          !favoritesIDs.contains(id);
    }).toList();
    // 🔥 🔥 🔥 FİLTRELEME SONU 🔥 🔥 🔥
    if (filtered.isEmpty) {
      return const Center(
        child: Text('Filtrelerinizle eşleşen yeni kişi bulunamadı.'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];

        final List<String> userCourses =
            (user['courses'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final String userRating =
            (user['rating'] as num?)?.toDouble().toStringAsFixed(1) ?? '0.0';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user['name'] ?? 'Bilinmeyen Kullanıcı'),
            subtitle: Text('Eşleşilen Dersler: ${userCourses.join(', ')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(userRating),
                const SizedBox(width: 10),

                // 1. İSTEK GÖNDERME BUTONU
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendRequest(
                      user['_id'] ?? '',
                      user['name'] ?? 'kullanıcı',
                    );
                  },
                ),

                // 2. PUANLAMA BUTONU
                IconButton(
                  icon: const Icon(Icons.rate_review),
                  onPressed: () => _showRatingDialog(
                    context,
                    user['name'] ?? 'Kullanıcı',
                    user['_id'] ?? '',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
