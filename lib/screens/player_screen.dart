import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/widgets/glowing_artwork.dart';
import 'package:sifat_audio/widgets/wave_progress_bar.dart';

class PlayerScreen extends StatelessWidget {
  final String heroTagPrefix;
  const PlayerScreen({super.key, this.heroTagPrefix = 'artwork_'});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final song = audioProvider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              color: Colors.white,
              iconSize: 30,
              splashRadius: 20,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.queue_music),
                color: Colors.white,
                iconSize: 30,
                splashRadius: 20,
                onPressed: () => _showQueueBottomSheet(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Colors.black,
                    ],
                  ),
                ),
              ),
              // Content
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final availableWidth = constraints.maxWidth;
                  final isLandscape = availableWidth > availableHeight;

                  if (isLandscape) {
                    // Landscape Layout (Keep as is for now or update if needed)
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Artwork Side
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Hero(
                                  tag: '$heroTagPrefix${song.id}',
                                  child: GlowingArtwork(
                                    isPlaying: audioProvider.isPlaying,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child:
                                          song.getMap.containsKey('artwork_url')
                                          ? Image.network(
                                              song.getMap['artwork_url']
                                                  as String,
                                              height: 1000,
                                              width: 1000,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: const Color(
                                                        0xFF2A2A2A,
                                                      ),
                                                      child: const Icon(
                                                        Icons.music_note,
                                                        size: 100,
                                                        color: Colors.white,
                                                      ),
                                                    );
                                                  },
                                            )
                                          : QueryArtworkWidget(
                                              id: song.id,
                                              type: ArtworkType.AUDIO,
                                              keepOldArtwork: true,
                                              artworkHeight: 1000,
                                              artworkWidth: 1000,
                                              quality: 100,
                                              artworkFit: BoxFit.cover,
                                              nullArtworkWidget: Container(
                                                color: const Color(0xFF2A2A2A),
                                                child: const Icon(
                                                  Icons.music_note,
                                                  size: 100,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Controls Side
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Title & Artist
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          song.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          song.artist ?? "Unknown Artist",
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Controls
                                  _buildControls(
                                    context,
                                    audioProvider,
                                    song,
                                    width: availableWidth * 0.4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Portrait Layout
                    final maxArtworkSize = (availableHeight * 0.45).clamp(
                      100.0,
                      availableWidth - 40,
                    );

                    return PageView(
                      children: [
                        // Page 1: Artwork & Controls
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: availableHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).padding.top + 10,
                                ),
                                // Artwork
                                Container(
                                  width: maxArtworkSize,
                                  height: maxArtworkSize,
                                  padding: const EdgeInsets.all(20.0),
                                  child: Hero(
                                    tag: '$heroTagPrefix${song.id}',
                                    child: GlowingArtwork(
                                      isPlaying: audioProvider.isPlaying,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child:
                                            song.getMap.containsKey(
                                              'artwork_url',
                                            )
                                            ? Image.network(
                                                song.getMap['artwork_url']
                                                    as String,
                                                height: 1000,
                                                width: 1000,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: const Color(
                                                          0xFF2A2A2A,
                                                        ),
                                                        child: const Icon(
                                                          Icons.music_note,
                                                          size: 100,
                                                          color: Colors.white,
                                                        ),
                                                      );
                                                    },
                                              )
                                            : QueryArtworkWidget(
                                                id: song.id,
                                                type: ArtworkType.AUDIO,
                                                keepOldArtwork: true,
                                                artworkHeight: 1000,
                                                artworkWidth: 1000,
                                                quality: 100,
                                                artworkFit: BoxFit.cover,
                                                nullArtworkWidget: Container(
                                                  color: const Color(
                                                    0xFF2A2A2A,
                                                  ),
                                                  child: const Icon(
                                                    Icons.music_note,
                                                    size: 100,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Title & Artist
                                Flexible(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            song.title,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            song.artist ?? "Unknown Artist",
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              audioProvider.isStream
                                                  ? "Playing from Online"
                                                  : "${audioProvider.currentIndex + 1}/${audioProvider.songs.length}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Controls
                                Flexible(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: _buildControls(
                                      context,
                                      audioProvider,
                                      song,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Page 2: Lyrics Placeholder
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lyrics,
                                size: 80,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Lyrics",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No lyrics available for this song.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Next Tracks",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.translucent,
                        child: Consumer<AudioProvider>(
                          builder: (context, audioProvider, child) {
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: audioProvider.songs.length,
                              itemBuilder: (context, index) {
                                final song = audioProvider.songs[index];
                                final isPlaying =
                                    audioProvider.currentIndex == index;
                                return ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/music_icon.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: QueryArtworkWidget(
                                      id: song.id,
                                      type: ArtworkType.AUDIO,
                                      keepOldArtwork: true,
                                      artworkBorder: BorderRadius.circular(8),
                                      nullArtworkWidget: const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isPlaying
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.white,
                                      fontWeight: isPlaying
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    song.artist ?? "Unknown Artist",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  trailing: isPlaying
                                      ? Icon(
                                          Icons.graphic_eq,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    audioProvider.playSong(index);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControls(
    BuildContext context,
    AudioProvider audioProvider,
    dynamic song, {
    double? width,
  }) {
    return Container(
      width: width ?? MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Controls (Shuffle & Favorite)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    size: 28,
                    color: audioProvider.isShuffleEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () => audioProvider.toggleShuffle(),
                ),
                IconButton(
                  icon: Icon(
                    audioProvider.isFavorite(song.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 28,
                    color: audioProvider.isFavorite(song.id)
                        ? Colors.red
                        : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () => audioProvider.toggleFavorite(song.id),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Slider
            WaveProgressBar(
              value: audioProvider.position.inSeconds.toDouble().clamp(
                0.0,
                audioProvider.duration.inSeconds.toDouble(),
              ),
              min: 0,
              max: audioProvider.duration.inSeconds.toDouble() > 0
                  ? audioProvider.duration.inSeconds.toDouble()
                  : 1.0,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.white.withOpacity(0.3),
              onChanged: (value) {
                audioProvider.seek(Duration(seconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(audioProvider.position),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(audioProvider.duration),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Main Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    size: 45,
                    color: Colors.white,
                  ),
                  onPressed: () => audioProvider.playPrevious(),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      audioProvider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      if (audioProvider.isPlaying) {
                        audioProvider.pause();
                      } else {
                        audioProvider.resume();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    size: 45,
                    color: Colors.white,
                  ),
                  onPressed: () => audioProvider.playNext(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
