import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/socket_service.dart';
import 'package:sky_high/pages/splash/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sky_high/firebase_options.dart';
import 'package:sky_high/widgets/connectivity_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Re-enable runtime fetching for Google Fonts to support Poppins
  GoogleFonts.config.allowRuntimeFetching = true;

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  GetIt.I.registerSingleton<StorageService>(storageService);

  // Initialize OneSignal on startup only if user is already logged in
  final userData = storageService.getUserData();
  if (userData != null) {
    final userId = userData['id']?.toString();
    StorageService.initOneSignal(userId);
  }

  // Register and initialize Socket.IO Service
  final socketService = SocketService();
  GetIt.I.registerSingleton<SocketService>(socketService);
  socketService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      GetIt.I<SocketService>().disconnect();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      debugPrint('MyApp: App is terminating, disconnecting Socket.IO...');
      try {
        GetIt.I<SocketService>().disconnect();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
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
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
      home: const SplashPage(),
    );
  }
}
