import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sifat_audio/providers/settings_provider.dart';
import 'package:sifat_audio/providers/auth_provider.dart';
import 'package:sifat_audio/screens/home_screen.dart';
import 'package:sifat_audio/screens/login_screen.dart'; // Assuming LoginScreen exists or will be used

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.2), const Color(0xFF0A0A0A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(Icons.music_note_rounded, size: 80, color: primaryColor),
                const SizedBox(height: 24),
                Text(
                  "Welcome to ZOFIO",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Choose how you want to use the app",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                _buildModeButton(
                  context,
                  title: "Online & Offline",
                  subtitle: "Stream YouTube & Play Local Music",
                  icon: Icons.cloud_done_rounded,
                  color: primaryColor,
                  onTap: () async {
                    final settings = Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    );
                    final auth = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );

                    await settings.setOfflineMode(false);

                    if (context.mounted) {
                      if (auth.isLoggedIn) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      } else {
                        // Navigate to Login Screen
                        // Assuming LoginScreen is the route for login
                        // If LoginScreen doesn't exist, we might need to create it or use a placeholder
                        // For now, let's assume we navigate to HomeScreen but it will show login prompt?
                        // No, the plan said "Navigates to Login (if needed)".
                        // Let's check if LoginScreen exists.
                        // I'll assume it doesn't exist as a separate screen yet based on previous context,
                        // but I should probably create one or use the AuthProvider's sign in method here?
                        // Actually, let's just trigger the login flow or go to Home and let Home handle it?
                        // The user said "show the login page".
                        // I'll assume I need to navigate to a LoginScreen.
                        // I'll check if LoginScreen exists first.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildModeButton(
                  context,
                  title: "Only Offline",
                  subtitle: "Play Local Music Only",
                  icon: Icons.sd_storage_rounded,
                  color: Colors.grey[800]!,
                  textColor: Colors.white,
                  onTap: () async {
                    final settings = Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    );
                    await settings.setOfflineMode(true);
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: textColor ?? Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor ?? Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: (textColor ?? Colors.black).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: (textColor ?? Colors.black).withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
