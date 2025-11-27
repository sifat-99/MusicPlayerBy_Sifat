import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/theme_provider.dart';
import 'package:sifat_audio/screens/settings_screen.dart';
import 'package:sifat_audio/screens/favorites_screen.dart';

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
            color: Colors.black.withOpacity(0.7),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.graphic_eq,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ZOFIO',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.white),
                  title: const Text(
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
                  leading: const Icon(Icons.settings, color: Colors.white),
                  title: const Text(
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
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
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
                          return GestureDetector(
                            onTap: () {
                              Provider.of<ThemeProvider>(
                                context,
                                listen: false,
                              ).setPrimaryColor(color);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
