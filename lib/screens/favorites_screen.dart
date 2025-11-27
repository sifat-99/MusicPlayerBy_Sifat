import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/screens/player_screen.dart';
import 'package:sifat_audio/widgets/song_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Favorites",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.6),
              Colors.black,
            ],
          ),
        ),
        child: Consumer<AudioProvider>(
          builder: (context, audioProvider, child) {
            final favoriteSongs = audioProvider.favoriteSongs;

            if (favoriteSongs.isEmpty) {
              return const Center(
                child: Text(
                  "No favorites yet",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                bottom: 20,
              ),
              itemCount: favoriteSongs.length,
              itemBuilder: (context, index) {
                final song = favoriteSongs[index];
                return SongTile(
                  song: song,
                  isPlaying:
                      audioProvider.currentSong?.id == song.id &&
                      audioProvider.isPlaying,
                  onTap: () {
                    // Find the index of this song in the main list to play it
                    // Or we could play from favorites list specifically if we supported playlists
                    // For now, let's find it in the main list
                    final mainIndex = audioProvider.songs.indexWhere(
                      (s) => s.id == song.id,
                    );
                    if (mainIndex != -1) {
                      audioProvider.playSong(mainIndex);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlayerScreen(heroTagPrefix: 'fav_'),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
