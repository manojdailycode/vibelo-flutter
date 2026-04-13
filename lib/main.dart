import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'services/audio_handler.dart';
import 'screens/splash_screen.dart';

late VibeleAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF070B14),
    ),
  );

  // Firebase — add google-services.json first (see SETUP.md)
  await Firebase.initializeApp();

  // Background audio
  audioHandler = await AudioService.init(
    builder: () => VibeleAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.vibelo.app.audio',
      androidNotificationChannelName: 'Vibelo Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(VibeleApp(handler: audioHandler));
}

class VibeleApp extends StatelessWidget {
  final VibeleAudioHandler handler;
  const VibeleApp({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(handler)),
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
