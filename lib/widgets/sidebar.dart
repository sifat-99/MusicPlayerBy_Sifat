import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/theme_provider.dart';
import 'package:sifat_audio/screens/settings_screen.dart';
import 'package:sifat_audio/screens/favorites_screen.dart';
import 'package:sifat_audio/providers/auth_provider.dart';
import 'package:sifat_audio/screens/login_screen.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 30), // Add top padding
                          if (auth.isLoggedIn)
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(
                                auth.user?.photoURL ?? '',
                              ),
                            )
                          else
                            Icon(
                              Icons.graphic_eq,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            auth.isLoggedIn
                                ? (auth.user?.displayName ?? 'User')
                                : 'ZOFIO',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                          ),
                          if (!auth.isLoggedIn)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.login,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(
                                "Sign In",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          if (auth.isLoggedIn)
                            TextButton.icon(
                              onPressed: () async {
                                await auth.signOut();
                                if (context.mounted) {
                                  Navigator.pop(context); // Close drawer
                                }
                              },
                              icon: Icon(
                                Icons.logout,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(
                                "Logout",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.favorite, color: Colors.white),
                  title: Text(
                    'Favorites',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title: Text(
                    'Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const Divider(color: Colors.grey),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Theme Color',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            [
                              Colors.deepPurple,
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.pink,
                              Colors.teal,
                              Colors.indigo,
                              Colors.cyan,
                              Colors.lime,
                              Colors.purple,
                              Colors.blueGrey,
                              Colors.brown,
                              Colors.deepOrange,
                              Colors.greenAccent,
                              Colors.indigoAccent,
                              Colors.orangeAccent,
                              Colors.pinkAccent,
                              Colors.purpleAccent,
                              Colors.redAccent,
                              Colors.tealAccent,
                              Colors.yellowAccent,
                              Colors.grey,
                              Colors.black,
                            ].map((color) {
                              final isSelected =
                                  themeProvider.primaryColor.value ==
                                  color.value;
                              return GestureDetector(
                                onTap: () {
                                  themeProvider.setPrimaryColor(color);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
