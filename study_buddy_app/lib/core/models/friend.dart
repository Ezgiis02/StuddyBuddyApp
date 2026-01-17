class Friend {
  final String id;
  final String name;
  final String? profileImageUrl;
  final double averageRating;
  final String? city;
  final String? district;
  final String? departmentName;
  final String? preferredLocationsText;

  Friend({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.averageRating = 0.0,
    this.city,
    this.district,
    this.departmentName,
    this.preferredLocationsText,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? '',
      name: json['name'] ?? 'İsimsiz',
      profileImageUrl: json['profileImageUrl'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      city: json['city'],
      district: json['district'],
      departmentName:
          json['departmentName'], // Backend'den bu isimle geldiğinden emin olun
      preferredLocationsText: json['preferredLocationsText'],
    );
  }
}
