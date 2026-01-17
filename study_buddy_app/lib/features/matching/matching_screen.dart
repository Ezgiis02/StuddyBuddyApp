import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import 'package:study_buddy_app/core/services/department_service.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  List<dynamic> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  // Eşleşmeleri API'den çek
  Future<void> _loadMatches() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    var matches = await ApiService().getMatches();
    if (mounted) {
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    }
  }

  // İstek Gönderme Mantığı
  void _onSendRequestPressed(Map<String, dynamic> user) {
    final List commonCourses = user['commonCourses'] ?? [];

    if (commonCourses.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ortak ders bulunamadı.")));
      return;
    }

    if (commonCourses.length == 1) {
      _sendRequest(
        user['id'],
        commonCourses[0]['id'],
        commonCourses[0]['courseCode'],
      );
    } else {
      _showCourseSelectionSheet(user, commonCourses);
    }
  }

  // Çoklu ders seçimi için BottomSheet
  void _showCourseSelectionSheet(Map<String, dynamic> user, List courses) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${user['name']} ile hangi dersi çalışmak istersin?",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ...courses
                  .map(
                    (course) => ListTile(
                      leading: const Icon(Icons.book, color: Colors.deepPurple),
                      title: Text(
                        course['courseCode'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(course['courseName']),
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendRequest(
                          user['id'],
                          course['id'],
                          course['courseCode'],
                        );
                      },
                    ),
                  )
                  .toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendRequest(
    String receiverId,
    String courseId,
    String courseName,
  ) async {
    bool success = await ApiService().sendFriendRequest(receiverId, courseId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "$courseName için istek gönderildi!"
                : "İstek gönderilemedi.",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) _loadMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadMatches,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final user = _matches[index] as Map<String, dynamic>;
                  return _buildUserCard(user);
                },
              ),
            ),
    );
  }

  // Ekranda kimse yoksa gösterilecek alan
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Şu an eşleşen kimse yok.\nOrtak derslerin olduğu kişileri burada göreceksin.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // DINAMIK KART YAPISI (Database odaklı)
  Widget _buildUserCard(Map<String, dynamic> user) {
    final List commonCourses = user['commonCourses'] ?? [];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profil Resmi ve Ortalama Puan
                Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.deepPurple.shade50,
                      backgroundImage:
                          (user['ProfileImageUrl'] != null &&
                              user['ProfileImageUrl'] != "")
                          ? NetworkImage(user['ProfileImageUrl'])
                          : null,
                      child:
                          (user['ProfileImageUrl'] == null ||
                              user['ProfileImageUrl'] == "")
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.deepPurple,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(
                          " ${(user['averageRating'] ?? 0.0).toStringAsFixed(1)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // 2. Database'den Gelen Dinamik Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? "İsimsiz",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bölüm Bilgisi
                      _buildInfoRow(
                        Icons.school,
                        DepartmentService.getName(
                          user['departmentId'] ?? user['DepartmentId'],
                        ),
                      ),

                      // Konum (City / District)
                      _buildInfoRow(
                        Icons.location_on,
                        "${user['City'] ?? 'Bursa'} / ${user['District'] ?? 'Osmangazi'}",
                      ),

                      // Mekan Tercihi (PreferredLocationsText)
                      _buildInfoRow(
                        Icons.local_cafe,
                        user['PreferredLocationsText'] ?? "Belirtilmedi",
                        isItalic: true,
                      ),
                    ],
                  ),
                ),

                // 3. Aksiyon Butonu
                Container(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _onSendRequestPressed(user),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Alt Kısım: Ortak Ders Sayısı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${commonCourses.length} Ortak Ders",
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Küçük Bilgi Satırları İçin Yardımcı Widget
  Widget _buildInfoRow(IconData icon, String text, {bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
