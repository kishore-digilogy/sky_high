import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/splash/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sky_high/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize OneSignal
  // Remove this method to stop OneSignal Debug logs
  OneSignal.Debug.setLogLevel(OSLogLevel.debug);

  OneSignal.initialize("8a517530-af11-446d-ae13-4ec77e3f99c9");

  // The prompt for push notification permissions
  OneSignal.Notifications.requestPermission(true);

  // Re-enable runtime fetching for Google Fonts to support Poppins
  GoogleFonts.config.allowRuntimeFetching = true;

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
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme(),
        dialogTheme: DialogThemeData(
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF475569),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        colorSchemeSeed: const Color(0xFF6C63FF),
      ),
      home: const SplashPage(),
    );
  }
}
