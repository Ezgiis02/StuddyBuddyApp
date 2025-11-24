// lib/core/models/user.dart (SON SÜRÜM)

import 'favorite_user.dart'; // FavoriteUser ve IncomingRequest'lar için

class User {
  final String id;
  final String name;
  final String email;
  final double rating;
  final List<String> courses;
  final List<FavoriteUser> favorites;
  final List<FavoriteUser> incomingRequests; // <-- BU ALAN EKLENDİ

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.rating,
    required this.courses,
    required this.favorites,
    required this.incomingRequests,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final List<FavoriteUser> favoritesList =
        (json['favorites'] as List<dynamic>?)
            ?.map((item) => FavoriteUser.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    final List<FavoriteUser> incomingRequestsList =
        (json['incomingRequests'] as List<dynamic>?)
            ?.map((item) => FavoriteUser.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return User(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Bilinmeyen Kullanıcı',
      email: json['email'] as String? ?? 'bilinmiyor@mail.com',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      favorites: favoritesList,
      incomingRequests: incomingRequestsList,
    );
  }
}
