// lib/core/models/course.dart

class Course {
  final String id;
  final String code;
  final String name;
  final String department;
  final int studentCount;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    this.studentCount = 0,
  });

  // API'den gelen JSON verisini Course objesine dönüştüren factory metot
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      studentCount: json['studentCount'] as int? ?? 0,
    );
  }

  // Kullanıcının bu dersi seçip seçmediğini kontrol etmek için
  // İleride kullanılacak bir alan (şimdilik varsayılan false)
  bool isSelected = false;
}
