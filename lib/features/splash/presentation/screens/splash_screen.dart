import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sudut_kota/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StreamSubscription<dynamic> _authSubscription;

  @override
  void initState() {
    super.initState();
    print("SPLASHSCREEN: initState() dijalankan.");

    // Mulai mendengarkan perubahan status otentikasi
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      print("SPLASHSCREEN: onAuthStateChange terdeteksi!"); // <-- Log 1
      if (session == null) {
        print("SPLASHSCREEN: Sesi NULL, navigasi ke /login"); // <-- Log 2
        context.go('/login');
      } else {
        print("SPLASHSCREEN: Sesi DITEMUKAN, navigasi ke /home"); // <-- Log 3
        context.go('/home');
      }
    });

    _redirectInitial();
  }

  void _redirectInitial() {
    // Cek sesi saat ini hanya saat pertama kali aplikasi dibuka
    print("SPLASHSCREEN: Pengecekan awal (_redirectInitial)");
    final session = supabase.auth.currentSession;
    if (session == null) {
      print("SPLASHSCREEN: Pengecekan awal -> Tidak ada sesi.");
      // Arahkan ke login jika tidak ada sesi awal setelah beberapa saat
      Future.delayed(const Duration(seconds: 1), () {
         // Pastikan widget masih ada di tree sebelum navigasi
        if (mounted && supabase.auth.currentSession == null) {
          context.go('/login');
        }
      });
    } else {
      print("SPLASHSCREEN: Pengecekan awal -> Sesi ditemukan, navigasi ke /home");
      context.go('/home');
    }
  }

  @override
  void dispose() {
    print("SPLASHSCREEN: dispose() dipanggil, subscription dibatalkan.");
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan splash screen tetap sama
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SudutKota',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}