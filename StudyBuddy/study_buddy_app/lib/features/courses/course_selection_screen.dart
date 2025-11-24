// lib/features/courses/course_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_buddy_app/core/models/course.dart';

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  List<Course> _allCourses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final String _fetchApiUrl = 'http://10.0.2.2:3000/api/courses';
  final String _saveApiUrl = 'http://10.0.2.2:3000/api/auth/update-courses';
  final String _profileApiUrl = 'http://10.0.2.2:3000/api/auth/profile';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Dersleri çek ve kullanıcının mevcut derslerini işaretle
  Future<void> _fetchCourses() async {
    try {
      // Tüm dersleri çek
      final response = await http.get(Uri.parse(_fetchApiUrl));
      if (response.statusCode != 200) {
        setState(() {
          _errorMessage =
              'Dersler yüklenirken hata oluştu: ${response.statusCode}';
          _isLoading = false;
        });
        return;
      }

      final coursesJson = jsonDecode(response.body)['courses'] as List<dynamic>;

      // Kullanıcının mevcut seçili derslerini al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwtToken');

      List<String> userCourses = [];
      if (token != null) {
        final profileResp = await http.get(
          Uri.parse(_profileApiUrl),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (profileResp.statusCode == 200) {
          final profileBody = jsonDecode(profileResp.body);
          userCourses = List<String>.from(profileBody['user']['courses']);
        }
      }

      // Tüm dersleri Course objesine çevir ve kullanıcının seçili derslerini işaretle
      setState(() {
        _allCourses = coursesJson.map((json) {
          final course = Course.fromJson(json);
          if (userCourses.contains(course.code)) {
            course.isSelected = true;
          }
          return course;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: API sunucunuz çalışıyor mu?';
        _isLoading = false;
        print('HTTP Hatası: $e');
      });
    }
  }

  // Seçilen dersleri kaydet
  Future<void> _saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');

    if (token == null) {
      _showSnackBar('Oturum süreniz dolmuş, tekrar giriş yapın.', Colors.red);
      return;
    }

    final selectedCourseCodes = _allCourses
        .where((course) => course.isSelected)
        .map((course) => course.code)
        .toList();

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse(_saveApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'courses': selectedCourseCodes}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Dersler başarıyla kaydedildi!', Colors.green);
        if (mounted) Navigator.of(context).pop(true); // HomeScreen güncellensin
      } else {
        final responseBody = jsonDecode(response.body);
        _showSnackBar(
          responseBody['message'] ?? 'Ders kaydında bir hata oluştu.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Bağlantı hatası: Sunucuya ulaşılamıyor.', Colors.red);
      print('HTTP Hata (Save): $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Seçimi'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Icon(Icons.done_all),
            onPressed: _isLoading ? null : _saveCourses,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _allCourses.length,
      itemBuilder: (context, index) {
        final course = _allCourses[index];
        return CheckboxListTile(
          title: Text(
            course.code,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(course.name),
          value: course.isSelected,
          onChanged: (bool? value) {
            setState(() {
              course.isSelected = value!;
            });
          },
        );
      },
    );
  }
}
