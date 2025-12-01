import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/widgets/mini_player.dart';
import 'package:sifat_audio/widgets/sidebar.dart';
import 'package:sifat_audio/widgets/folder_list.dart';
import 'package:sifat_audio/widgets/home_tab.dart';
import 'package:sifat_audio/widgets/local_songs_tab.dart';

import 'package:sifat_audio/widgets/library_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeTab(),
      // Songs Tab
      const LocalSongsTab(),
      // Library Tab
      const LibraryTab(),
      const FolderList(),
    ];

    return Scaffold(
      extendBody: true, // Allow body to extend behind NavBar
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05),
      drawer: const Sidebar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.6),
              Theme.of(context).primaryColor.withOpacity(0.2),
              Theme.of(context).primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Stack(
          children: [
            pages[_selectedIndex],
            const Positioned(
              bottom: 100, // Above NavBar
              left: 0,
              right: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              indicatorColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
              labelTextStyle: MaterialStateProperty.all(
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              iconTheme: WidgetStateProperty.all(
                const IconThemeData(color: Colors.white),
              ),
            ),
            child: NavigationBar(
              height: 70,
              backgroundColor: Colors.black.withValues(alpha: 0.8),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note),
                  label: 'Songs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: 'Folders',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
