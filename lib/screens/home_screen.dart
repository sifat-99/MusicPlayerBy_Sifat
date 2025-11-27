import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/screens/player_screen.dart';
import 'package:sifat_audio/widgets/album_list.dart';
import 'package:sifat_audio/widgets/artist_list.dart';
import 'package:sifat_audio/widgets/mini_player.dart';
import 'package:sifat_audio/widgets/sidebar.dart';
import 'package:sifat_audio/widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _alphabet = List.generate(
    26,
    (index) => String.fromCharCode(index + 65),
  );

  void _scrollToLetter(String letter, List<dynamic> songs) {
    int index = songs.indexWhere(
      (song) => song.title.toUpperCase().startsWith(letter),
    );
    if (index != -1) {
      // Approximate height of SongTile is 72 + margin 8 = 80
      _scrollController.animateTo(
        index * 80.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  String _activeLetter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).requestPermission();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Approximate item height 80.0
    final index = (_scrollController.offset / 80.0).floor();
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (index >= 0 && index < audioProvider.songs.length) {
      final song = audioProvider.songs[index];
      final firstLetter = song.title.isNotEmpty
          ? song.title[0].toUpperCase()
          : '#';
      if (_activeLetter != firstLetter) {
        setState(() {
          _activeLetter = firstLetter;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        drawer: const Sidebar(),
        appBar: AppBar(
          title: const Text(
            "Sifat Audio",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tabs: const [
              Tab(text: "Songs"),
              Tab(text: "Artists"),
              Tab(text: "Albums"),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.6),
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Colors.black,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height:
                        MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        70, // Adjusted for new TabBar padding
                  ), // For AppBar + TabBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        Provider.of<AudioProvider>(
                          context,
                          listen: false,
                        ).filterSongs(value);
                      },
                      decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Songs Tab
                        Consumer<AudioProvider>(
                          builder: (context, audioProvider, child) {
                            if (audioProvider.songs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No songs found",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(
                                      bottom: 80,
                                    ), // Space for MiniPlayer
                                    itemCount: audioProvider.songs.length,
                                    itemBuilder: (context, index) {
                                      final song = audioProvider.songs[index];
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: Duration(
                                          milliseconds: 300 + (index * 50),
                                        ),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(0, 50 * (1 - value)),
                                            child: Opacity(
                                              opacity: value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: SongTile(
                                          song: song,
                                          isPlaying:
                                              audioProvider.currentIndex ==
                                                  index &&
                                              audioProvider.isPlaying,
                                          onTap: () {
                                            audioProvider.playSong(index);
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                    ) => const PlayerScreen(
                                                      heroTagPrefix:
                                                          'list_artwork_',
                                                    ),
                                                transitionsBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child,
                                                    ) {
                                                      const begin = Offset(
                                                        0.0,
                                                        1.0,
                                                      );
                                                      const end = Offset.zero;
                                                      const curve = Curves.ease;

                                                      var tween =
                                                          Tween(
                                                            begin: begin,
                                                            end: end,
                                                          ).chain(
                                                            CurveTween(
                                                              curve: curve,
                                                            ),
                                                          );

                                                      return SlideTransition(
                                                        position: animation
                                                            .drive(tween),
                                                        child: child,
                                                      );
                                                    },
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  width: 30,
                                  color: Colors.black.withOpacity(0.3),
                                  child: GestureDetector(
                                    onVerticalDragUpdate: (details) {
                                      final index =
                                          (details.localPosition.dy / 20)
                                              .floor();
                                      if (index >= 0 &&
                                          index < _alphabet.length) {
                                        _scrollToLetter(
                                          _alphabet[index],
                                          audioProvider.songs,
                                        );
                                      }
                                    },
                                    child: ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _alphabet.length,
                                      itemBuilder: (context, index) {
                                        final letter = _alphabet[index];
                                        final isActive =
                                            letter == _activeLetter;
                                        return GestureDetector(
                                          onTap: () {
                                            _scrollToLetter(
                                              letter,
                                              audioProvider.songs,
                                            );
                                          },
                                          child: Container(
                                            height: 20,
                                            alignment: Alignment.center,
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                color: isActive
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.white,
                                                fontSize: isActive ? 14 : 10,
                                                fontWeight: isActive
                                                    ? FontWeight.w900
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // Artists Tab
                        const ArtistList(),
                        // Albums Tab
                        const AlbumList(),
                      ],
                    ),
                  ),
                ],
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MiniPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
