class Course {
  final String id;
  final String courseName;
  final String courseCode;
  final String department;
  final String description;
  final int credits;
  final int semester;
  // Enumları string veya int olarak alabiliriz, basitlik için şimdilik string varsayalım
  // veya sadece ekranda göstereceğimiz temel verileri alalım.

  Course({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.department,
    required this.description,
    required this.credits,
    required this.semester,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? json['_id'] ?? "",
      courseName: json['CourseName'] ?? json['courseName'] ?? "İsimsiz Ders",
      courseCode: json['CourseCode'] ?? json['courseCode'] ?? "",
      department: json['Department'] ?? json['department'] ?? "",
      description: json['Description'] ?? json['description'] ?? "",
      // int.tryParse kullanarak string gelse bile sayıya çevirmeyi deniyoruz
      credits:
          int.tryParse(
            json['Credits']?.toString() ?? json['credits']?.toString() ?? "0",
          ) ??
          0,
      semester:
          int.tryParse(
            json['Semester']?.toString() ?? json['semester']?.toString() ?? "1",
          ) ??
          1,
    );
  }
}
