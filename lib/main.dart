import 'package:flutter/material.dart';
import 'package:sudut_kota/core/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hghsudbqzzztzlpgbfex.supabase.co', 

    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnaHN1ZGJxenp6dHpscGdiZmV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNTYyMDAsImV4cCI6MjA2NzYzMjIwMH0.JjhgcmNrr_vahlvV5R38Lc2Nl84oyQkakNG8BnG9FBQ', 
  );

  runApp(const MyApp());
}


final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan MaterialApp.router untuk mengaktifkan go_router
    return MaterialApp.router(
      title: 'SudutKota',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      // Beritahu MaterialApp untuk menggunakan konfigurasi router kita
      routerConfig: appRouter,
    );
  }
}