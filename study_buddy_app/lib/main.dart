import 'package:flutter/material.dart';
// Oluşturduğumuz ekranları import ediyoruz
import 'features/authentication/login_screen.dart';
import 'features/authentication/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/courses/course_selection_screen.dart';
import 'features/matching/matching_screen.dart';
import 'core/theme/theme.dart';
import 'core/config/theme_service.dart'; // Tema servisi
import 'package:study_buddy_app/core/services/department_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama başlamadan önce bölümleri çekiyoruz
  await DepartmentService.init();
  runApp(const StudyBuddyApp());
}

class StudyBuddyApp extends StatefulWidget {
  const StudyBuddyApp({super.key});

  @override
  // State sınıfını oluşturuyoruz
  State<StudyBuddyApp> createState() => _StudyBuddyAppState();
}

class _StudyBuddyAppState extends State<StudyBuddyApp> {
  // Tema servisini dinle: Sayfa yüklendiğinde listener'ı ekle
  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);
  }

  // Sayfa kapanırken listener'ı kaldır
  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  // Tema değiştiğinde bu fonksiyon çalışır ve setState ile build metodunu tetikler
  void _onThemeChanged() {
    setState(() {});
  }

  // Düzeltildi: build metodu artık State sınıfının içinde yer alıyor.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Proje amacına uygun bir başlık
      title: 'StudyBuddy - Çalışma Arkadaşı Bulma Uygulaması',

      // Temalar
      theme: lightTheme,
      darkTheme: darkTheme,

      // Global servisten tema modunu oku
      themeMode: themeService.themeMode, // <-- TEMA BURADAN KONTROL EDİLİYOR
      // Uygulama başladığında ilk açılacak sayfa: Giriş Ekranı
      initialRoute: '/login',

      // Uygulama içindeki tüm yönlendirmeleri (Route) tanımlıyoruz
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        // Ders Seçimi rotası, Home'un içinde push/pop ile de kullanıldığı için burada kalabilir.
        '/select-courses': (context) => const CourseSelectionScreen(),
        '/matching': (context) => const MatchingScreen(),
      },
    );
  }
}
