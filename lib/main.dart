import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        fontFamily: 'Inter',
        colorSchemeSeed: const Color(0xFF6C63FF),
      ),
      home: const SplashPage(),
    );
  }
}
