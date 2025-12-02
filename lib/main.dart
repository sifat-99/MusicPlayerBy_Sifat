import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/audio_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sifat_audio/providers/auth_provider.dart';
import 'firebase_options.dart';
import 'services/update_service.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/launcher_icon',
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider2<
          SettingsProvider,
          AuthProvider,
          AudioProvider
        >(
          create: (_) => AudioProvider(),
          update: (_, settings, auth, audio) {
            audio!.update(settings, auth);
            return audio;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    final latestVersion = await UpdateService.checkForUpdate();
    if (latestVersion != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              "Update Required",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "A new version ($latestVersion) is available. Please update to continue using the app.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  UpdateService.launchUpdateUrl();
                },
                child: const Text(
                  "Update Now",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, SettingsProvider, AuthProvider>(
      builder: (context, themeProvider, settingsProvider, authProvider, child) {
        return MaterialApp(
          title: 'ZOFIO',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(
              0xFF0A0A0A,
            ), // Deep dark background
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.primaryColor,
              brightness: Brightness.dark,
              surface: const Color(0xFF121212),
              background: const Color(0xFF0A0A0A),
              primary: themeProvider.primaryColor,
              onPrimary: Colors.black,
              secondary: themeProvider.primaryColor,
              onSecondary: Colors.black,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0A0A0A),
              elevation: 0,
              centerTitle: true,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF121212),
              indicatorColor: themeProvider.primaryColor.withOpacity(0.2),
              labelTextStyle: MaterialStateProperty.all(
                GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            textTheme: GoogleFonts.outfitTextTheme(
              ThemeData.dark().textTheme,
            ).apply(bodyColor: Colors.white, displayColor: Colors.white),
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settingsProvider.fontSize),
              ),
              child: child!,
            );
          },
          home: _getStartScreen(settingsProvider, authProvider),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
        );
      },
    );
  }

  Widget _getStartScreen(
    SettingsProvider settingsProvider,
    AuthProvider authProvider,
  ) {
    if (settingsProvider.isOfflineMode == null) {
      return const ModeSelectionScreen();
    }

    if (settingsProvider.isOfflineMode!) {
      return const HomeScreen();
    }

    // Online Mode
    if (authProvider.isLoggedIn) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
