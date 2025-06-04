// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor
  AppTheme._();

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark, // Penting untuk dark mode
    primaryColor: Colors.blueGrey[900], // Contoh warna primer
    scaffoldBackgroundColor: Colors.grey[850], // Warna latar belakang utama
    // primarySwatch: Colors.teal, // Bisa juga menggunakan primarySwatch

    // Atur warna aksen jika diperlukan
    // accentColor: Colors.tealAccent, // Deprecated, gunakan colorScheme.secondary
    colorScheme: ColorScheme.dark(
      primary: Colors.teal,       // Warna utama untuk komponen seperti AppBar
      secondary: Colors.tealAccent, // Warna untuk FloatingActionButton, switch, dll.
      surface: Colors.grey[800]!,   // Warna permukaan Card, Dialog
      background: Colors.grey[850]!,// Warna latar belakang aplikasi
      error: Colors.redAccent,
      onPrimary: Colors.white,      // Warna teks/ikon di atas warna primer
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),

    // Atur tema untuk teks
    textTheme: TextTheme(
      headlineSmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white70),
      titleLarge: TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic, color: Colors.white60),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind', color: Colors.white),
      // Anda bisa mendefinisikan lebih banyak style teks
    ),

    // Atur tema untuk AppBar
    appBarTheme: AppBarTheme(
      color: Colors.grey[900], // Warna AppBar
      elevation: 4.0,
      iconTheme: IconThemeData(color: Colors.white), // Warna ikon di AppBar
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Atur tema untuk Tombol
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal, // Warna latar tombol
        foregroundColor: Colors.white, // Warna teks tombol
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: TextStyle(fontSize: 16),
      ),
    ),

    // Atur tema untuk Card
    cardTheme: CardTheme(
      color: Colors.grey[800],
      elevation: 2.0,
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),

    // Atur tema untuk InputDecorator (TextFormField)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[700],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.tealAccent),
      ),
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white54),
    ),

    // Dan lain-lain sesuai kebutuhan
  );

  // Jika Anda ingin punya Light Theme juga (untuk nanti)
  // static final ThemeData lightTheme = ThemeData(...);
}