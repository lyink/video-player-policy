import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/media_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/playlist_provider.dart';
import 'screens/main_screen.dart';
import 'services/admob_service.dart';
import 'services/simple_audio_service.dart';
import 'services/intent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob
  await AdMobService.initialize();

  // Initialize Simple Audio Service
  try {
    await SimpleAudioService.instance.initialize();
  } catch (e) {
    print('Failed to initialize audio service: $e');
    // Continue without audio service for fallback
  }

  // Initialize Intent Service
  try {
    await IntentService.initialize();
  } catch (e) {
    print('Failed to initialize intent service: $e');
  }

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const VideoPlayerApp());
}

class VideoPlayerApp extends StatefulWidget {
  const VideoPlayerApp({super.key});

  @override
  State<VideoPlayerApp> createState() => _VideoPlayerAppState();
}

class _VideoPlayerAppState extends State<VideoPlayerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Show app-open ad on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAppOpenAdIfAvailable();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showAppOpenAdIfAvailable();
    }
  }

  void _showAppOpenAdIfAvailable() {
    if (AdMobService.isAppOpenAdAvailable) {
      AdMobService.showAppOpenAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider.value(value: SimpleAudioService.instance),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Video Player',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getTheme(themeProvider.currentTheme),
            themeMode: themeProvider.themeMode,
            home: const MainScreen(),
            builder: (context, child) {
              // Ensure proper text scaling
              final currentScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    currentScaleFactor.clamp(0.8, 1.2),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
