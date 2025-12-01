import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/screens/player_screen.dart';
import 'package:sifat_audio/widgets/song_tile.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LocalSongsTab extends StatefulWidget {
  const LocalSongsTab({super.key});

  @override
  State<LocalSongsTab> createState() => _LocalSongsTabState();
}

class _LocalSongsTabState extends State<LocalSongsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";
  String _activeLetter = "";
  List<SongModel> _currentFilteredSongs = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_currentFilteredSongs.isEmpty) return;

    // Estimate index based on scroll position (assuming ~72px per item)
    final offset = _scrollController.offset;
    final index = (offset / 72.0).floor().clamp(
      0,
      _currentFilteredSongs.length - 1,
    );

    final song = _currentFilteredSongs[index];
    final title = song.title.toUpperCase();
    String letter = '#';
    if (title.isNotEmpty) {
      final firstChar = title[0];
      if (RegExp(r'[A-Z]').hasMatch(firstChar)) {
        letter = firstChar;
      }
    }

    if (_activeLetter != letter) {
      setState(() {
        _activeLetter = letter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    // Filter and sort songs
    // IMPORTANT: Create a COPY of the list to avoid modifying the provider's list in place
    // which would desync it from the internal playlist.
    List<SongModel> filteredSongs = List.from(audioProvider.songs);
    if (_searchQuery.isNotEmpty) {
      filteredSongs = filteredSongs.where((song) {
        return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (song.artist?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    }

    // Ensure sorted alphabetically for A-Z sidebar
    filteredSongs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    _currentFilteredSongs = filteredSongs;

    if (filteredSongs.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildSearchBar(),
              const Expanded(
                child: Center(
                  child: Text(
                    "No songs found",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const Center(
        child: Text("No songs found", style: TextStyle(color: Colors.white)),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      bottom: 100,
                    ), // Space for mini player
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return SongTile(
                        song: song,
                        isPlaying:
                            audioProvider.currentIndex != -1 &&
                            audioProvider.songs.indexOf(song) ==
                                audioProvider
                                    .currentIndex && // Check actual index match if possible, or ID
                            audioProvider.isPlaying,
                        onTap: () {
                          // We need to play from the MAIN list, so find the index in the main provider list
                          final realIndex = audioProvider.songs.indexOf(song);
                          if (realIndex != -1) {
                            audioProvider.playSong(realIndex);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlayerScreen(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                // A-Z Sidebar
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _buildAlphabetSidebar(filteredSongs)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search local songs...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 0,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlphabetSidebar(List<SongModel> songs) {
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: MediaQuery.of(context).size.height * 0.6, // Occupy 60% of height
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: alphabet.split('').map((letter) {
          final isActive = _activeLetter == letter;
          return GestureDetector(
            onTap: () {
              _scrollToLetter(letter, songs);
              setState(() {
                _activeLetter = letter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                letter,
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontSize: isActive ? 14 : 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _scrollToLetter(String letter, List<SongModel> songs) {
    int index = -1;
    if (letter == '#') {
      // Scroll to non-alphabetic
      index = songs.indexWhere((s) => !RegExp(r'^[a-zA-Z]').hasMatch(s.title));
    } else {
      index = songs.indexWhere((s) => s.title.toUpperCase().startsWith(letter));
    }

    if (index != -1) {
      // Estimate item height (SongTile height is approx 72)
      // For more accuracy, we'd need a scrollable list of keys, but this is a good approximation
      final offset = index * 72.0;
      _scrollController.jumpTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }
}
