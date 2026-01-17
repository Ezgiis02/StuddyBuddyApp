// 1. Yardımcı Sınıf: Puan Detayları
class UserRating {
  final String raterUserId;
  final int score;

  UserRating({required this.raterUserId, required this.score});

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      // Backend'den gelen Key'ler (C# tarafında genelde PascalCase olabilir)
      raterUserId: json['RaterUserId'] ?? json['raterUserId'] ?? '',
      score: json['Score'] ?? json['score'] ?? 0,
    );
  }
}

// 2. Ana Sınıf: Kullanıcı
class User {
  final String? id;
  final String name;
  final String email;
  final String? departmentId;
  final String? profileImageUrl;
  final String? city;
  final String? district;

  // EKLENEN KISIM: Profil düzenleme ekranındaki kırmızı çizginin sebebi buydu
  final String? preferredLocationsText;

  final List<String> courses;
  final List<String> favoriteUserIds;

  // EKLENEN KISIM: Eski int listesi yerine artık detaylı obje listesi
  final List<UserRating> ratings;
  final double averageRating;

  User({
    this.id,
    required this.name,
    required this.email,
    this.departmentId,
    this.profileImageUrl,
    this.city,
    this.district,
    this.preferredLocationsText, // Constructor'a eklendi
    this.courses = const [],
    this.favoriteUserIds = const [],
    this.ratings = const [],
    required this.averageRating,
  });

  // Dinamik Ortalama Hesaplama (Getter)
  // Ekranda "4.5 / 5.0" gibi göstermek için kullanılır
  double get rating {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold(0, (sum, item) => sum + item.score);
    return total / ratings.length;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['userId'] ?? json['_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      departmentId: json['departmentId'],
      profileImageUrl: json['profileImageUrl'],
      city: json['city'],
      district: json['district'],
      preferredLocationsText:
          json['PreferredLocationsText'] ?? json['preferredLocationsText'],

      courses:
          (json['selectedCourseIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      favoriteUserIds:
          (json['favoriteUserIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      ratings: json['ratings'] != null
          ? (json['ratings'] as List)
                .map((i) => UserRating.fromJson(i))
                .toList()
          : [],

      // 🔥 İŞTE BU
      averageRating: (json['averageRating'] ?? 0).toDouble(),
    );
  }
}
