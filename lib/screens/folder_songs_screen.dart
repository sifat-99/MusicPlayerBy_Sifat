import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/screens/player_screen.dart';
import 'package:sifat_audio/widgets/song_tile.dart';

class FolderSongsScreen extends StatelessWidget {
  final String folderName;
  final List<SongModel> songs;

  const FolderSongsScreen({
    super.key,
    required this.folderName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          folderName,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        child: ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            bottom: 20,
          ),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                return SongTile(
                  song: song,
                  isPlaying:
                      audioProvider.currentSong?.id == song.id &&
                      audioProvider.isPlaying,
                  onTap: () {
                    // Find index in main list to play
                    // Ideally we should support playing from folder list directly
                    // but for now let's find in main list
                    final mainIndex = audioProvider.songs.indexWhere(
                      (s) => s.id == song.id,
                    );
                    if (mainIndex != -1) {
                      audioProvider.playSong(mainIndex);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlayerScreen(heroTagPrefix: 'folder_'),
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
