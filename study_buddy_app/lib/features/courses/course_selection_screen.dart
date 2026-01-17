import 'package:flutter/material.dart';
import '../../core/models/course.dart';
import '../../core/services/api_service.dart';

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  List<Course> _allCourses = []; // Tüm dersler
  List<Course> _filteredCourses = []; // Arama sonucu filtrelenenler
  List<String> _myCourseIds = []; // Zaten ekli olanların ID'leri
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Paralel olarak hem tüm dersleri hem benim derslerimi çek
    var results = await Future.wait([
      ApiService().getAllCourses(),
      ApiService().getMyCourses(),
    ]);

    _allCourses = results[0] as List<Course>;
    var myCourses = results[1] as List<Course>;

    // Benim derslerimin sadece ID'lerini sakla (kontrol için)
    _myCourseIds = myCourses.map((c) => c.id).toList();
    _filteredCourses = _allCourses;

    setState(() => _isLoading = false);
  }

  // Arama Fonksiyonu
  void _filterCourses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = _allCourses;
      } else {
        _filteredCourses = _allCourses.where((course) {
          final code = course.courseCode.toLowerCase();
          final name = course.courseName.toLowerCase();
          final input = query.toLowerCase();
          return code.contains(input) || name.contains(input);
        }).toList();
      }
    });
  }

  // Ders Ekle/Çıkar İşlemi
  Future<void> _toggleCourse(String courseId, bool isCurrentlyAdded) async {
    // 1. Arayüzü hemen güncelle (Hissedilen hız artar)
    setState(() {
      if (isCurrentlyAdded) {
        _myCourseIds.remove(courseId);
      } else {
        _myCourseIds.add(courseId);
      }
    });

    // 2. API İsteği Gönder
    bool success;
    if (isCurrentlyAdded) {
      success = await ApiService().removeCourseFromUser(courseId);
    } else {
      success = await ApiService().addCourseToUser(courseId);
    }

    // 3. Hata olursa işlemi geri al
    if (!success) {
      setState(() {
        if (isCurrentlyAdded) {
          _myCourseIds.add(courseId); // Geri ekle
        } else {
          _myCourseIds.remove(courseId); // Geri çıkar
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("İşlem başarısız oldu.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ders Seçimi"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- ARAMA ÇUBUĞU ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCourses,
              decoration: InputDecoration(
                hintText: "Ders adı veya kodu ara (Örn: EE204)",
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),

          // --- DERS LİSTESİ ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                ? const Center(child: Text("Ders bulunamadı."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      final isAdded = _myCourseIds.contains(course.id);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          // Ders Kodu Kutucuğu
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isAdded
                                  ? Colors.green.shade100
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              course.courseCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAdded
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                          title: Text(
                            course.courseName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${course.department} • ${course.credits} Kredi",
                            style: const TextStyle(fontSize: 12),
                          ),
                          // Ekle / Çıkar Butonu
                          trailing: IconButton(
                            icon: Icon(
                              isAdded
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isAdded ? Colors.green : Colors.grey,
                              size: 32,
                            ),
                            onPressed: () => _toggleCourse(course.id, isAdded),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
