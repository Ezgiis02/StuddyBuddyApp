import 'dart:convert';
import 'package:dio/dio.dart';

class DepartmentService {
  static final Map<String, String> _deptMap = {};
  static final Dio _dio = Dio();

  // API'den tüm bölümleri çeker ve sözlüğe doldurur
  static Future<void> init() async {
    try {
      // Kendi API URL'ni buraya yaz (Örn: http://10.0.2.2:5000/api/departments)
      final response = await _dio.get('http://10.0.2.2:5258/api/departments');

      if (response.statusCode == 200) {
        final List departments = response.data;
        for (var dept in departments) {
          // MongoDB'den gelen id ve DepartmentName'i eşleştiriyoruz
          _deptMap[dept['id']] = dept['departmentName'];
        }
        print("✅ Bölümler başarıyla yüklendi: ${_deptMap.length} adet");
      }
    } catch (e) {
      print("❌ Bölümler yüklenirken hata oluştu: $e");
    }
  }

  // ID verince ismi döndüren metod
  static String getName(String? id) {
    if (id == null || id.isEmpty) return 'Bölüm Belirtilmedi';
    return _deptMap[id] ?? 'Bölüm Bulunamadı';
  }
}
