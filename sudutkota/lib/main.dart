// lib/main.dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart'; // Impor file tema Anda

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SudutKota',
      themeMode: ThemeMode.dark, // Memaksa Dark Mode
      theme: AppTheme.darkTheme, // Tema default (bisa juga light jika ada)
      darkTheme: AppTheme.darkTheme, // Tema spesifik untuk Dark Mode
      debugShowCheckedModeBanner: false, // Hilangkan banner debug
      home: const SplashScreen(), // Kita akan buat SplashScreen sederhana
    );
  }
}

// Contoh SplashScreen sederhana (buat file baru atau taruh di sini dulu)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigasi ke halaman login setelah beberapa detik
    Future.delayed(const Duration(seconds: 3), () {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => LoginPage()), // Ganti dengan halaman login Anda nanti
      // );
      print("Splash screen selesai, navigasi ke Login (belum dibuat)");
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan warna dari tema
    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.background, // Atau warna spesifik
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ganti dengan logo aplikasi Anda nanti
            Icon(
              Icons.explore_outlined, // Contoh ikon
              size: 80.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'SudutKota',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Menemukan Permata Tersembunyi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white70
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}