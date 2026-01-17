import 'package:flutter/material.dart';
import '../../core/models/user.dart';
import '../../core/services/api_service.dart'; // ApiService eklendi
import 'edit_profile_screen.dart';
import 'package:study_buddy_app/core/services/department_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  final User currentUser;
  final int totalFriendsCount;
  final VoidCallback? onProfileUpdate;

  const ProfileDetailScreen({
    super.key,
    required this.currentUser,
    this.totalFriendsCount = 0,
    this.onProfileUpdate,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  // --- BÖLÜM İSİMLERİ İÇİN DEĞİŞKENLER ---
  Map<String, String> _departmentMap = {};
  bool _isDeptLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  // Bölüm listesini çekip Map yapısına çeviren fonksiyon
  Future<void> _loadDepartments() async {
    try {
      final depts = await ApiService().getDepartmentMap();
      if (mounted) {
        setState(() {
          _departmentMap = depts;
          _isDeptLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDeptLoading = false);
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfileScreen(currentUser: widget.currentUser),
      ),
    );

    if (result == true && widget.onProfileUpdate != null) {
      widget.onProfileUpdate!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.currentUser.profileImageUrl != null &&
        widget.currentUser.profileImageUrl!.isNotEmpty;

    // Bölüm ismini çözme mantığı
    String userDeptId = widget.currentUser.departmentId ?? "";

    String displayDepartmentName = _isDeptLoading
        ? "Yükleniyor..."
        : (_departmentMap[userDeptId] ?? "Bölüm bulunamadı");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Profili Düzenle",
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- PROFİL RESMİ ---
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: hasImage
                    ? NetworkImage(widget.currentUser.profileImageUrl!)
                    : null,
                child: !hasImage
                    ? Icon(Icons.person, size: 80, color: Colors.grey.shade400)
                    : null,
              ),
            ),
            const SizedBox(height: 25),

            // --- BİLGİ KARTLARI ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.person,
                      'Ad Soyad',
                      widget.currentUser.name,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      Icons.email,
                      'E-posta',
                      widget.currentUser.email,
                    ),
                    const Divider(),

                    // --- BÖLÜM KISMI (GÜNCELLENDİ) ---
                    _buildInfoRow(
                      context,
                      Icons.school,
                      'Bölüm',
                      DepartmentService.getName(
                        widget.currentUser.departmentId,
                      ), // Artık ID değil İsim yazıyor
                    ),
                    const Divider(),

                    _buildInfoRow(
                      context,
                      Icons.star,
                      'Ortalama Puan',
                      '${widget.currentUser.averageRating.toStringAsFixed(1)} / 5.0',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      Icons.group,
                      'Arkadaş Sayısı',
                      '${widget.totalFriendsCount}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- KONUM VE TERCİHLER ---
            if (widget.currentUser.city != null ||
                widget.currentUser.preferredLocationsText != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (widget.currentUser.city != null) ...[
                        _buildInfoRow(
                          context,
                          Icons.location_city,
                          'Konum',
                          "${widget.currentUser.city} ${widget.currentUser.district != null ? '/ ${widget.currentUser.district}' : ''}",
                        ),
                        if (widget.currentUser.preferredLocationsText != null)
                          const Divider(),
                      ],

                      if (widget.currentUser.preferredLocationsText != null &&
                          widget.currentUser.preferredLocationsText!.isNotEmpty)
                        _buildInfoRow(
                          context,
                          Icons
                              .local_cafe, // İkon daha uygun bir hale getirildi
                          'Favori Mekanlar',
                          widget.currentUser.preferredLocationsText!,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
