import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'services/audio_handler.dart';
import 'screens/splash_screen.dart';

late VibeleAudioHandler audioHandler;

/// Initializes all services in the background after UI loads
Future<void> _initializeServices() async {
  // Firebase initialization
  try {
    await Firebase.initializeApp();
    debugPrint('✓ Firebase initialized');
  } catch (e) {
    debugPrint('✗ Firebase init failed: $e');
  }

  // Audio service initialization
  try {
    audioHandler = await AudioService.init(
      builder: () => VibeleAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.vibelo.app.audio',
        androidNotificationChannelName: 'Vibelo Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    debugPrint('✓ AudioService initialized');
  } catch (e) {
    debugPrint('✗ AudioService init failed: $e');
    audioHandler = VibeleAudioHandler();
  }
}

Future<void> main() async {
  // Only initialize UI bindings — this is lightning fast
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation — very fast
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar — very fast
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF070B14),
    ),
  );

  // Initialize a dummy audio handler for instant UI load
  audioHandler = VibeleAudioHandler();

  // Run app immediately — no blocking!
  runApp(const VibeleApp());

  // Initialize services in the background (app already showing)
  await _initializeServices();
}

class VibeleApp extends StatelessWidget {
  const VibeleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(audioHandler)),
        ChangeNotifierProxyProvider<AuthProvider, PlaylistProvider>(
          // `create` makes an initial instance with a dummy AuthProvider.
          // It's immediately updated by the `update` callback below.
          create: (context) => PlaylistProvider(authProvider: AuthProvider()),
          update: (context, auth, previous) =>
              previous!..updateAuthProvider(auth),
        ),
      ],
      child: MaterialApp(
        title: 'Vibelo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
