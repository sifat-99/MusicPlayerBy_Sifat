import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/screens/player_screen.dart';
import 'package:sifat_audio/widgets/song_tile.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sifat_audio/services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:sifat_audio/providers/auth_provider.dart';
import 'package:sifat_audio/providers/settings_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final YouTubeService _youtubeService = YouTubeService();
  List<yt.Video> _ytResults = [];
  bool _isSearchingYT = false;
  final TextEditingController _searchController = TextEditingController();

  List<SongModel> _quickPicks = [];
  List<SongModel> _biggestHits = [];
  bool _isLoadingHome = true;

  @override
  void initState() {
    super.initState();
    _fetchHomeContent();
  }

  Future<void> _fetchHomeContent() async {
    setState(() => _isLoadingHome = true);

    try {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final isOffline = settingsProvider.isOfflineMode ?? false;

      List<SongModel> mixedQuickPicks = [];
      List<SongModel> ytTrendingSongs = [];

      // Get Local Songs (shuffled for variety)
      final localSongs = List<SongModel>.from(audioProvider.songs)..shuffle();

      if (isOffline) {
        // Offline Mode: Only use local songs
        mixedQuickPicks = localSongs.take(10).toList();
      } else {
        // Online Mode: Fetch YouTube Content
        final ytQuickPicks = await _youtubeService.getQuickPicks();
        final ytTrending = await _youtubeService.getTrendingSongs();

        // Convert YT Videos to SongModels
        final ytQuickPicksSongs = ytQuickPicks.map(_videoToSongModel).toList();
        ytTrendingSongs = ytTrending.map(_videoToSongModel).toList();

        // Merge for Quick Picks (Interleave: 1 Local, 1 YT, etc.)
        int localIndex = 0;
        int ytIndex = 0;

        // Take up to 10 items total
        while (mixedQuickPicks.length < 10) {
          if (localIndex < localSongs.length) {
            mixedQuickPicks.add(localSongs[localIndex++]);
          }
          if (mixedQuickPicks.length < 10 &&
              ytIndex < ytQuickPicksSongs.length) {
            mixedQuickPicks.add(ytQuickPicksSongs[ytIndex++]);
          }
          if (localIndex >= localSongs.length &&
              ytIndex >= ytQuickPicksSongs.length) {
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _quickPicks = mixedQuickPicks;
          _biggestHits = ytTrendingSongs;
          _isLoadingHome = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching home content: $e");
      if (mounted) setState(() => _isLoadingHome = false);
    }
  }

  SongModel _videoToSongModel(yt.Video video) {
    return SongModel({
      '_id': video.id.value.hashCode,
      'title': video.title,
      'artist': video.author,
      '_data': video.url, // Store URL in data for streaming
      '_uri': video.url,
      'album': 'YouTube Music',
      'duration': video.duration?.inMilliseconds ?? 0,
      'is_music': true,
      'artwork_url': video.thumbnails.mediumResUrl,
    });
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchYouTube(String query) async {
    if (query.isEmpty) {
      setState(() {
        _ytResults = [];
        _isSearchingYT = false;
      });
      return;
    }

    setState(() {
      _isSearchingYT = true;
    });

    final results = await _youtubeService.searchSongs(query);

    if (mounted) {
      setState(() {
        _ytResults = results;
        _isSearchingYT = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    // Use fetched data, fallback to empty if loading
    final quickPicks = _quickPicks;
    final justUpdated = _biggestHits;

    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _fetchHomeContent,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              actions: [
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
                        child: auth.isLoggedIn && auth.user?.photoURL != null
                            ? CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(
                                  auth.user!.photoURL!,
                                ),
                              )
                            : const CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.transparent,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingHome)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    // Search Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Search songs, albums, or YouTube...",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            suffixIcon: _isSearchingYT
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      audioProvider.filterSongs("");
                                      setState(() {
                                        _ytResults = [];
                                      });
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onSubmitted: (value) {
                            final settings = Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            );
                            if (settings.isOfflineMode == false) {
                              _searchYouTube(value);
                            }
                            audioProvider.filterSongs(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        ).isOfflineMode ==
                        true) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[900]!, Colors.black],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.cloud_off_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Offline Mode",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Enjoy your local music library",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_ytResults.isNotEmpty) ...[
                      const Text(
                        "Online Results",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ytResults.length,
                        itemBuilder: (context, index) {
                          final video = _ytResults[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                video.thumbnails.mediumResUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                            title: Text(
                              video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              video.author,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (audioProvider.isDownloading(video.id.value))
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(
                                      Icons.download,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final info = await _youtubeService
                                          .getDownloadStream(video.id.value);
                                      if (info != null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Downloading..."),
                                            ),
                                          );
                                        }
                                        await audioProvider
                                            .downloadSongFromStream(
                                              info.stream,
                                              video.title,
                                              video.author,
                                              ext: info.ext,
                                              id: video.id.value,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Download complete!",
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    // Play directly using video ID (handled by proxy in AudioProvider)
                                    await audioProvider.playUrl(
                                      video.id.value,
                                      video.title,
                                      video.author,
                                      video.thumbnails.mediumResUrl,
                                    );
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PlayerScreen(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quick Picks Header
                    const Text(
                      "Quick picks",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick Picks Horizontal List
                    SizedBox(
                      height: 200, // Increased height for better spacing
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: quickPicks.length,
                        itemBuilder: (context, index) {
                          final song = quickPicks[index];
                          return GestureDetector(
                            onTap: () async {
                              if (song.getMap.containsKey('artwork_url')) {
                                // It's a YouTube stream
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                if (!authProvider.isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        "Please login to play online music",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await audioProvider.playUrl(
                                  song.data, // URL is stored in data
                                  song.title,
                                  song.artist ?? "Unknown",
                                  song.getMap['artwork_url'],
                                );
                              } else {
                                // It's a local song
                                final realIndex = audioProvider.songs
                                    .indexWhere((s) => s.id == song.id);
                                if (realIndex != -1) {
                                  audioProvider.playSong(realIndex);
                                }
                              }
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PlayerScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              height: double.infinity,
                                              child:
                                                  song.getMap.containsKey(
                                                    'artwork_url',
                                                  )
                                                  ? Image.network(
                                                      song.getMap['artwork_url'],
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.music_note,
                                                            size: 50,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : QueryArtworkWidget(
                                                      id: song.id,
                                                      type: ArtworkType.AUDIO,
                                                      keepOldArtwork: true,
                                                      nullArtworkWidget:
                                                          const Icon(
                                                            Icons.music_note,
                                                            size: 50,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.6,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                song.getMap.containsKey(
                                                      'artwork_url',
                                                    )
                                                    ? Icons.cloud
                                                    : Icons.sd_storage,
                                                size: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "Unknown",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Just Updated / Today's Hits Header
                    if (justUpdated.isNotEmpty) ...[
                      Text(
                        "Today's biggest hits - ${DateTime.now().day}  🔥",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            // Vertical List of Songs
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= justUpdated.length) return null;
                final song = justUpdated[index];
                return SongTile(
                  song: song,
                  onTap: () async {
                    if (song.getMap.containsKey('artwork_url')) {
                      // It's a YouTube stream
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      if (!authProvider.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Please login to play online music",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      await audioProvider.playUrl(
                        song.data, // URL is stored in data
                        song.title,
                        song.artist ?? "Unknown",
                        song.getMap['artwork_url'],
                      );
                    } else {
                      // It's a local song
                      // We need to find its index in the main provider list to play it properly
                      // OR we can just play it directly if we support playing arbitrary SongModel
                      // For now, let's try to find it in the main list, or play it as a single item playlist
                      final realIndex = audioProvider.songs.indexWhere(
                        (s) => s.id == song.id,
                      );
                      if (realIndex != -1) {
                        audioProvider.playSong(realIndex);
                      }
                    }
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlayerScreen()),
                      );
                    }
                  },
                  isPlaying:
                      audioProvider.currentSong?.id == song.id &&
                      audioProvider.isPlaying,
                );
              }, childCount: justUpdated.length),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ), // Bottom padding
          ],
        ),
      ),
    );
  }
}
