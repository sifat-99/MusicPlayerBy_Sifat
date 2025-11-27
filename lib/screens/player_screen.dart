import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';

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
          body: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -500) {
                // Swipe Up
                _showQueueBottomSheet(context);
              }
            },
            child: Stack(
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
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Artwork
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: '$heroTagPrefix${song.id}',
                          child: QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            keepOldArtwork: true,
                            artworkHeight: 1000,
                            artworkWidth: 1000,
                            quality: 100,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(height: 40),
                      // Title & Artist
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              song.title,
                              textAlign: TextAlign.center,
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
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Song Count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${audioProvider.currentIndex + 1}/${audioProvider.songs.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Controls with Glassmorphism
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Top Controls (Shuffle & Favorite)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.shuffle,
                                        size: 30,
                                        color: audioProvider.isShuffleEnabled
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                      onPressed: () =>
                                          audioProvider.toggleShuffle(),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        audioProvider.isFavorite(song.id)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 30,
                                        color: audioProvider.isFavorite(song.id)
                                            ? Colors.red
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                      onPressed: () =>
                                          audioProvider.toggleFavorite(song.id),
                                    ),
                                  ],
                                ),
                                // Slider
                                Slider(
                                  value: audioProvider.position.inSeconds
                                      .toDouble(),
                                  min: 0,
                                  max: audioProvider.duration.inSeconds
                                      .toDouble(),
                                  onChanged: (value) {
                                    audioProvider.seek(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(audioProvider.position),
                                      ),
                                      Text(
                                        _formatDuration(audioProvider.duration),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Buttons
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                      onPressed: () =>
                                          audioProvider.playPrevious(),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.5),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder:
                                              (child, animation) {
                                                return ScaleTransition(
                                                  scale: animation,
                                                  child: child,
                                                );
                                              },
                                          child: Icon(
                                            audioProvider.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            key: ValueKey<bool>(
                                              audioProvider.isPlaying,
                                            ),
                                            size: 60,
                                            color: Colors.white,
                                          ),
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
                                        Icons.skip_next,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => audioProvider.playNext(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
}
