import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime fetching for Google Fonts to use bundled fonts
  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();
  GetIt.I.registerSingleton<StorageService>(StorageService(prefs));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkyHigh',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        textTheme: GoogleFonts.outfitTextTheme(),
        dialogTheme: DialogThemeData(
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
          contentTextStyle: GoogleFonts.outfit(
            fontSize: 16,
            color: const Color(0xFF475569),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        colorSchemeSeed: const Color(0xFF6C63FF),
      ),
      home: const SplashPage(),
    );
  }
}
