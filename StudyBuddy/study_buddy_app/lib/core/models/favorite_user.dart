// lib/core/models/favorite_user.dart

class FavoriteUser {
  final String id;
  final String name;
  final double rating;
  final List<String> courses;

  FavoriteUser({
    required this.id,
    required this.name,
    required this.rating,
    required this.courses,
  });

  factory FavoriteUser.fromJson(Map<String, dynamic> json) {
    return FavoriteUser(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Bilinmeyen Kullanıcı',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
