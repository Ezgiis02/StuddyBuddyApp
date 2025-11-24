import 'package:flutter/material.dart';
import 'package:study_buddy_app/core/models/user.dart';

class ProfileDetailScreen extends StatelessWidget {
  final User currentUser;
  final int totalFriendsCount;

  const ProfileDetailScreen({
    super.key,
    required this.currentUser,
    this.totalFriendsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 80),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kişisel Bilgiler',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),

          _buildInfoRow(context, Icons.person, 'Ad Soyad', currentUser.name),
          _buildInfoRow(context, Icons.email, 'E-posta', currentUser.email),
          _buildInfoRow(
            context,
            Icons.star,
            'Ortalama Puan',
            '${currentUser.rating.toStringAsFixed(1)} / 5.0',
          ),
          _buildInfoRow(
            context,
            Icons.group,
            'Toplam Arkadaş',
            '${currentUser.favorites.length} Kişi',
          ),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bilgiler Güncelleniyor...')),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Profili Düzenle/Fotoğraf Ekle'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
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
        children: [
          Icon(icon, color: Colors.blueGrey, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
