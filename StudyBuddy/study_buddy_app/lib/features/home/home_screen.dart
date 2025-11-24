import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:study_buddy_app/core/models/user.dart';
import 'package:study_buddy_app/core/models/favorite_user.dart';
import 'package:study_buddy_app/features/courses/course_selection_screen.dart';
import 'package:study_buddy_app/features/matching/matching_screen.dart';
import 'package:study_buddy_app/core/config/theme_service.dart';
import 'package:study_buddy_app/features/home/profile_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  bool _isLoading = true;
  int _selectedIndex = 0;

  final String _profileApiUrl = 'http://10.0.2.2:3000/api/auth/profile';
  final String _handleRequestUrl =
      'http://10.0.2.2:3000/api/users/handle-request';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

  void _toggleTheme() {
    themeService.toggleTheme();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwtToken');

    if (token == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_profileApiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        setState(() {
          _currentUser = User.fromJson(responseBody['user']);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('jwtToken');
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('Profil yüklenirken bir hata oluştu.', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Bağlantı Hatası: API sunucunuz çalışıyor mu?',
          Colors.red,
        );
      }
    }
  }

  Future<void> _handleCoursesUpdate() async {
    final bool? coursesUpdated = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CourseSelectionScreen()),
    );

    if (coursesUpdated == true) {
      await _loadUserProfile();
    }
  }

  Future<void> _handleRequest(String senderId, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse(_handleRequestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'senderId': senderId, 'action': action}),
      );

      if (response.statusCode == 200) {
        final message = action == 'accept'
            ? 'İstek kabul edildi ve favorilere eklendi.'
            : 'İstek reddedildi.';
        _showSnackBar(message, Colors.green);
        await _loadUserProfile();
      } else {
        _showSnackBar('İşlem başarısız oldu.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Bağlantı hatası: İşlem yapılamadı.', Colors.red);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _buildHomeScreenTab() {
    final userRating = _currentUser?.rating ?? 0.0;
    final List<FavoriteUser> userFavorites = _currentUser?.favorites ?? [];
    final List<FavoriteUser> userIncomingRequests =
        _currentUser?.incomingRequests ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı kartı
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş Geldin, ${_currentUser?.name ?? 'Kullanıcı'}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 5),
                          Text('Puan: ${userRating.toStringAsFixed(1)} / 5.0'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Gelen Çalışma İstekleri
          const Text(
            'Gelen Çalışma İstekleri:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),

          if (userIncomingRequests.isEmpty)
            Center(
              child: Text(
                'Gelen çalışma isteğiniz bulunmamaktadır.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...userIncomingRequests
                .map(
                  (sender) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        sender.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Puan: ${sender.rating.toStringAsFixed(1)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                _handleRequest(sender.id, 'accept'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                _handleRequest(sender.id, 'reject'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),

          const SizedBox(height: 40),

          // Favori Arkadaşlar
          const Text(
            'Favori Çalışma Arkadaşların:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),

          if (userFavorites.isEmpty)
            Center(
              child: Text(
                'Henüz favori arkadaşınız yok.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: userFavorites
                  .map(
                    (favoriteUser) => Chip(
                      avatar: const CircleAvatar(
                        child: Icon(Icons.person, size: 16),
                      ),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favoriteUser.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.color,
                            ),
                          ),
                          Text(
                            'Puan: ${favoriteUser.rating.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall!.color,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).cardTheme.color,
                      padding: const EdgeInsets.all(8),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    final userCourses = _currentUser?.courses ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _handleCoursesUpdate,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Ders Ekle/Düzenle'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 30),

          const Text(
            'Seçili Derslerin:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),

          if (userCourses.isEmpty)
            Center(
              child: Text(
                'Henüz ders eklenmedi.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: userCourses
                  .map(
                    (courseCode) => Chip(
                      label: Text(
                        courseCode,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> widgetOptions = <Widget>[
      _buildHomeScreenTab(),
      _buildCoursesTab(),
      const MatchingScreen(),
      ProfileDetailScreen(
        currentUser: _currentUser!,
        totalFriendsCount: _currentUser!.favorites.length,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyBuddy'),
        actions: [
          IconButton(
            icon: Icon(
              themeService.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: _toggleTheme,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Dersler'),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add),
            label: 'Arkadaş Bul',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
