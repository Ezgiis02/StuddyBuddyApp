import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../features/courses/course_selection_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/models/user.dart';
import '../../core/models/course.dart';
import '../../core/models/friend.dart';

import '../../features/matching/matching_screen.dart';
import '../../core/config/theme_service.dart';
import 'profile_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  List<Course> _myCourses = [];
  List<dynamic> _pendingRequests = [];
  List<Friend> _myFriends = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  List<Course> _allCourses = []; // Veritabanındaki tüm dersler
  List<Course> _filteredAllCourses = []; // Arama yapınca filtrelenenler
  final TextEditingController _searchController =
      TextEditingController(); // Arama kutusu için
  // Arkadaş bul sayfasını yenilemeye zorlamak için bir anahtar
  Key _matchingKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService().getUserProfile(),
        ApiService().getMyCourses(),
        ApiService().getPendingRequests(),
        ApiService().getMyFriends(),
        ApiService().getAllCourses(),
      ]);

      final profileResponse = results[0] as Response;
      if (profileResponse.statusCode == 200) {
        final data = profileResponse.data;
        final userData =
            (data is Map<String, dynamic> && data.containsKey('user'))
            ? data['user']
            : data;
        _currentUser = User.fromJson(userData);
      }

      _myCourses = results[1] as List<Course>;
      _pendingRequests = results[2] as List<dynamic>;
      _myFriends = results[3] as List<Friend>;
      _allCourses = results[4] as List<Course>;
      _filteredAllCourses = _allCourses;
    } on DioException catch (e) {
      print("Veri yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  void _filterCourses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAllCourses = _allCourses;
      } else {
        _filteredAllCourses = _allCourses.where((course) {
          final code = course.courseCode.toLowerCase();
          final name = course.courseName.toLowerCase();
          final input = query.toLowerCase();
          return code.contains(input) || name.contains(input);
        }).toList();
      }
    });
  }

  // --- 2. DERS EKLE / ÇIKAR FONKSİYONU ---
  Future<void> _toggleCourse(String courseId, bool isCurrentlyAdded) async {
    // Arayüzü anında güncelle (Hız hissi için)
    setState(() {
      final course = _allCourses.firstWhere((c) => c.id == courseId);
      if (isCurrentlyAdded) {
        _myCourses.removeWhere((c) => c.id == courseId);
      } else {
        _myCourses.add(course);
      }
    });

    // Arka planda API'ye gönder
    bool success;
    if (isCurrentlyAdded) {
      success = await ApiService().removeCourseFromUser(courseId);
    } else {
      success = await ApiService().addCourseToUser(courseId);
    }

    // Hata olursa verileri eski haline getirmek için tekrar yükle
    if (!success) _loadData();
  }

  void _toggleTheme() {
    themeService.toggleTheme();
  }

  Future<void> _handleRequest(String requestId, bool accept) async {
    bool success;
    if (accept) {
      success = await ApiService().acceptRequest(requestId);
    } else {
      success = await ApiService().rejectRequest(requestId);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? "Kabul edildi!" : "Reddedildi."),
          backgroundColor: accept ? Colors.green : Colors.grey,
        ),
      );
      _loadData();
    }
  }

  void _showDeleteConfirmDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Arkadaşı Sil"),
        content: Text(
          "$friendName kişisini arkadaş listenizden çıkarmak istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await ApiService().removeFriend(friendId);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "$friendName silindi. Tekrar 'Arkadaş Bul' kısmında görünebilir.",
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                setState(() {
                  _matchingKey = UniqueKey();
                });
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Hata oluştu."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (context) {
        int selectedScore = 5;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("$friendName kişisini puanla"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedScore
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () =>
                            setState(() => selectedScore = index + 1),
                      );
                    }),
                  ),
                  Text("$selectedScore / 5 Puan"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    bool success = await ApiService().rateUser(
                      friendId,
                      selectedScore,
                    );
                    if (success) {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Puan kaydedildi!")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Puan kaydedilirken hata oluştu."),
                        ),
                      );
                    }
                  },
                  child: const Text("Gönder"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- TASARIM BURADA DEĞİŞTİ ---
  Widget _buildHomeScreenTab() {
    if (_currentUser == null) return const SizedBox();

    return SingleChildScrollView(
      // Padding'i kaldırdım, header tam genişlik olsun diye
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER ALANI (Renkli Arka Plan)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.deepPurple, // Temana göre renk değiştirebilirsin
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: _currentUser!.profileImageUrl != null
                            ? NetworkImage(_currentUser!.profileImageUrl!)
                            : null,
                        child: _currentUser!.profileImageUrl == null
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Merhaba, ${_currentUser!.name} 👋",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Puanın: ${_currentUser!.rating.toStringAsFixed(1)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TERCİHLER KARTI (Transform ile yukarı kaydırıp modern görünüm verdik)
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📌 Çalışma Tercihlerin",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(height: 20),
                      // Şehir / İlçe Bilgisi
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Konum",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "${_currentUser!.city ?? '-'} / ${_currentUser!.district ?? '-'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Tercih Edilen Yerler Bilgisi
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_cafe,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Favori Mekanlar",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _currentUser!.preferredLocationsText ??
                                      "Henüz belirtilmedi.",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. BEKLEYEN İSTEKLER
                if (_pendingRequests.isNotEmpty) ...[
                  const Text(
                    "🔔 Bekleyen İstekler",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final req = _pendingRequests[index];
                      return Card(
                        color: Colors.orange.shade50,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(
                            req['senderName'] ?? "Bilinmeyen",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text("Ders çalışmak istiyor!"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 30,
                                ),
                                onPressed: () =>
                                    _handleRequest(req['requestId'], true),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                onPressed: () =>
                                    _handleRequest(req['requestId'], false),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. ARKADAŞ LİSTESİ
                const Text(
                  "👥 Çalışma Arkadaşlarım",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),

                if (_myFriends.isNotEmpty)
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _myFriends[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                friend.profileImageUrl != null &&
                                    friend.profileImageUrl!.isNotEmpty
                                ? NetworkImage(friend.profileImageUrl!)
                                : null,
                            child:
                                (friend.profileImageUrl == null ||
                                    friend.profileImageUrl!.isEmpty)
                                ? const Icon(Icons.face)
                                : null,
                          ),
                          title: Text(
                            friend.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "⭐ ${friend.averageRating.toStringAsFixed(1)}",
                            style: TextStyle(color: Colors.amber[800]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.star_rate_rounded,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                tooltip: "Puan Ver",
                                onPressed: () =>
                                    _showRatingDialog(friend.id, friend.name),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 26,
                                ),
                                tooltip: "Arkadaşı Sil",
                                onPressed: () => _showDeleteConfirmDialog(
                                  friend.id,
                                  friend.name,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.group_off, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            "Henüz çalışma arkadaşın yok.\n'Arkadaş Bul' sekmesinden yeni insanlarla tanış!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 25),

                // 5. DERSLER
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "📚 Derslerim",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Ders eklemek için aşağıdaki 'Dersler' sekmesine git.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 15),

                if (_myCourses.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 40,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Henüz ders eklemediniz.",
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  )
                else
                  // Yatay kaydırma yerine dikey liste (ListView)
                  ListView.builder(
                    // Bu ayarlar listeyi sayfanın kaydırmasına dahil eder
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myCourses.length,
                    itemBuilder: (context, index) {
                      final course = _myCourses[index];
                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ), // Kartlar arası boşluk
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Sol Taraf: Ders Kodu
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                course.courseCode,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),

                            // Orta Kısım: Ders Adı
                            Expanded(
                              child: Text(
                                course.courseName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            // Sağ Taraf: Silme Butonu
                            InkWell(
                              onTap: () => _toggleCourse(course.id, true),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    return Column(
      children: [
        // Üst Arama Kutusu
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ders Ekle",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: _filterCourses,
                decoration: InputDecoration(
                  hintText: "Ders adı veya kodu ara (Örn: EE204)",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.deepPurple,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: _filteredAllCourses.isEmpty
              ? const Center(child: Text("Ders bulunamadı."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredAllCourses.length,
                  itemBuilder: (context, index) {
                    final course = _filteredAllCourses[index];
                    // Bu ders zaten ekli mi kontrol et
                    final isAdded = _myCourses.any((c) => c.id == course.id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          course.courseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "${course.courseCode} • ${course.credits} Kredi",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isAdded
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: isAdded ? Colors.green : Colors.grey,
                            size: 28,
                          ),
                          onPressed: () => _toggleCourse(course.id, isAdded),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> widgetOptions = <Widget>[
      _buildHomeScreenTab(),
      _buildCoursesTab(),
      MatchingScreen(key: _matchingKey),
      if (_currentUser != null)
        ProfileDetailScreen(
          currentUser: _currentUser!,
          totalFriendsCount: _myFriends.length,
          onProfileUpdate: () {
            // Profil düzenlenip geri dönüldüğünde verileri tekrar çek
            _loadData();
          },
        )
      else
        const Center(child: Text("Hata")),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyBuddy'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) _loadData();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Dersler'),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add),
            label: 'Arkadaş Bul',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
