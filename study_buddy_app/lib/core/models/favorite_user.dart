class FavoriteUser {
  final int id; // String yerine int
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
      // MongoDB _id veya SQL id desteği
      id: json['id'] ?? json['_id'] ?? 0,
      name: json['name'] ?? 'Bilinmeyen Kullanıcı',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
