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
        ChangeNotifierProxyProvider<SettingsProvider, AudioProvider>(
          create: (_) => AudioProvider(),
          update: (_, settings, audio) {
            audio!.updateSettings(settings);
            return audio;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
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
            home: const HomeScreen(),
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
            ),
          );
        },
      ),
    ),
  );
}
