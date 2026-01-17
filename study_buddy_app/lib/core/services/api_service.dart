import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/friend.dart';

class ApiService {
  // Emülatör için 10.0.2.2, Gerçek Cihaz için Bilgisayarın IP'si (örn: 192.168.1.x)
  static const String baseUrl = "http://10.0.2.2:5258/api";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- AUTH (GİRİŞ / KAYIT) ---
  Future<Response> login(String email, String password) async {
    return await _dio.post(
      '/auth/login',
      data: {"email": email, "password": password},
    );
  }

  Future<Response> register(
    String name,
    String email,
    String password,
    String confirmPassword,
    String departmentId,
  ) async {
    return await _dio.post(
      '/auth/register',
      data: {
        "name": name,
        "email": email,
        "password": password,
        "confirmPassword": confirmPassword,
        "departmentId": departmentId,
      },
    );
  }

  Future<Map<String, String>> getDepartmentMap() async {
    try {
      // Backend'deki DepartmentsController'dan tüm listeyi alıyoruz
      final response = await _dio.get('/department');
      if (response.statusCode == 200) {
        final List data = response.data;
        // Listeyi hızlı arama yapılabilecek bir Map'e çeviriyoruz
        return {
          for (var item in data)
            item['_id'].toString(): item['DepartmentName'].toString(),
        };
      }
    } catch (e) {
      print("Bölümler yüklenirken hata: $e");
    }
    return {};
  }

  // --- USER PROFILE (PROFİL) ---
  Future<Response> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    // Mobilden gelen istekte userId'yi parametre olarak ekliyoruz
    return await _dio.get('/user/profile?userId=$userId');
  }

  // --- COURSES (DERSLER) ---
  // --- DERS İŞLEMLERİ (COURSES) ---

  // 1. Tüm Dersleri Getir
  Future<List<Course>> getAllCourses() async {
    try {
      final response = await _dio.get('/courses/getall');
      return (response.data as List).map((x) => Course.fromJson(x)).toList();
    } catch (e) {
      print("Tüm dersleri getirme hatası: $e");
      return [];
    }
  }

  // 2. Benim Derslerimi Getir
  Future<List<Course>> getMyCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      // Backend'deki GetMyCourses parametresine uygun istek
      final response = await _dio.get('/courses/getmycourses?userId=$userId');
      return (response.data as List).map((x) => Course.fromJson(x)).toList();
    } catch (e) {
      print("Benim derslerim hatası: $e");
      return [];
    }
  }

  // 3. Ders Ekle
  Future<bool> addCourseToUser(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      await _dio.post('/courses/add/$courseId?userId=$userId');
      return true;
    } catch (e) {
      print("Ders ekleme hatası: $e");
      return false;
    }
  }

  // 4. Ders Sil
  Future<bool> removeCourseFromUser(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      await _dio.delete('/courses/remove/$courseId?userId=$userId');
      return true;
    } catch (e) {
      print("Ders silme hatası: $e");
      return false;
    }
  }

  // --- MATCHING (EŞLEŞME) ---
  Future<List<dynamic>> getMatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Backend'deki /api/matching/suggestions rotasına gidiyoruz
      final response = await _dio.get('/matching/suggestions?userId=$userId');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Eşleşme getirme hatası: $e");
      return [];
    }
  }

  // 2. Arkadaşlık İsteği Gönder (Ders ID ile)
  Future<bool> sendFriendRequest(String receiverId, String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Backend'deki /api/matching/send-request rotasına gidiyoruz
      await _dio.post(
        '/matching/send-request',
        data: {
          "senderId": userId,
          "receiverId": receiverId,
          "courseId": courseId,
        },
      );

      return true;
    } catch (e) {
      print("İstek gönderme hatası: $e");
      return false;
    }
  }

  // 3. İsteği Kabul Et
  Future<bool> acceptRequest(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Backend: StudyRequestController -> api/request/accept/{requestId}
      await _dio.post('/request/accept/$requestId?userId=$userId');

      return true;
    } catch (e) {
      print("İstek kabul hatası: $e");
      return false;
    }
  }

  // 4. İsteği Reddet
  Future<bool> rejectRequest(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Backend: StudyRequestController -> api/request/reject/{requestId}
      await _dio.post('/request/reject/$requestId?userId=$userId');

      return true;
    } catch (e) {
      print("İstek reddetme hatası: $e");
      return false;
    }
  }

  // 5. Bekleyen İstekleri Getir
  // Backend: StudyRequestController -> /api/request/pending
  Future<List<dynamic>> getPendingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final response = await _dio.get('/request/pending?userId=$userId');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Bekleyen istekleri getirme hatası: $e");
      return [];
    }
  }

  // 6. Arkadaşlarımı Getir
  // Backend: StudyRequestController -> /api/request/myfriends
  Future<List<Friend>> getMyFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final response = await _dio.get('/request/myfriends?userId=$userId');

      if (response.statusCode == 200) {
        // Gelen JSON verisini Friend model listesine çeviriyoruz
        return (response.data as List)
            .map((json) => Friend.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print("Arkadaşları getirme hatası: $e");
      return [];
    }
  }

  // --- RATING (OYLAMA) ---
  // EKSİK OLAN METOD 👇
  // 8. Kullanıcı Puanla (Yeni Hibrit Controller'a Uygun)
  Future<bool> rateUser(String ratedUserId, int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? currentUserId = prefs.getString('userId');

      if (currentUserId == null) {
        print("Hata: Kullanıcı ID bulunamadı.");
        return false;
      }

      // Backend'deki yeni rotaya istek atıyoruz
      final response = await _dio.post(
        '/rating/rate?userId=$currentUserId',
        data: {
          "ratedUserId": ratedUserId, // Backend'deki ViewModel ile aynı isim
          "score": score,
        },
      );

      // Sunucu 200 dönerse başarılı sayıyoruz
      return response.statusCode == 200;
    } on DioException catch (e) {
      // Hata durumunda konsola detay yazdır (Debug için çok önemli)
      print("Puanlama Sunucu Hatası: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Beklenmedik Puanlama Hatası: $e");
      return false;
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Backend'deki endpoint: DELETE /api/request/removefriend/{friendId}?userId=...
      await _dio.delete('/request/removefriend/$friendId?userId=$userId');

      return true;
    } catch (e) {
      print("Arkadaş silme hatası: $e");
      return false;
    }
  }

  // --- DEPARTMENTS (BÖLÜMLER) ---
  // Kayıt ekranında göstermek için bölümleri çeker
  Future<List<dynamic>> getAllDepartments() async {
    try {
      // Backend'de bu rotanın (GET /api/departments) açık olduğundan emin olmalısın.
      // Eğer yoksa C# tarafında basit bir Controller ile listeyi dönmen gerekir.
      final response = await _dio.get('/departments');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Bölümleri getirme hatası: $e");
      return [];
    }
  }

  // --- LOCATIONS (Şehir/İlçe) ---
  // Web'deki LocationsController ile konuşur
  Future<List<String>> getCities() async {
    try {
      final response = await _dio.get('/locations/cities');
      return List<String>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getDistricts(String city) async {
    try {
      final response = await _dio.get('/locations/districts?city=$city');
      return List<String>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  // --- LOCATION UPDATE (SADECE KONUM GÜNCELLEME) ---
  // Backend'deki [HttpPost("update-location")] ile konuşur
  Future<bool> updateLocation(
    String city,
    String district,
    String preferredLocations,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final response = await _dio.post(
        '/user/update-location?userId=$userId',
        data: {
          "city": city,
          "district": district,
          "preferredLocationsText":
              preferredLocations, // Backend'e bu alanı da gönderiyoruz
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Konum güncelleme hatası: $e");
      return false;
    }
  }

  // --- PROFILE UPDATE (RESİMLİ GÜNCELLEME) ---
  Future<bool> updateProfile({
    required String name,
    required String? city,
    required String? district,
    required String? preferredLocations,
    String? filePath, // Seçilen resmin dosya yolu (Varsa)
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Resim göndereceğimiz için FormData kullanıyoruz
      FormData formData = FormData.fromMap({
        "UserId": userId,
        "Name": name,
        "City": city ?? "",
        "District": district ?? "",
        "PreferredLocationsText": preferredLocations ?? "",
      });

      // Eğer yeni resim seçildiyse ekle
      if (filePath != null) {
        formData.files.add(
          MapEntry(
            "ProfileImage", // Backend'deki parametre adıyla AYNI olmalı
            await MultipartFile.fromFile(filePath, filename: "profile.jpg"),
          ),
        );
      }

      final response = await _dio.put(
        // Genelde güncelleme PUT olur, POST ise değiştirirsin
        '/userapi/update',
        data: formData,
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      return false;
    }
  }

  // --- ŞİFRE DEĞİŞTİRME ---
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final response = await _dio.post(
        '/user/changepassword',
        data: {
          "userId": userId,
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
