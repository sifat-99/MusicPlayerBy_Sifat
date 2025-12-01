import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sifat_audio/screens/folder_songs_screen.dart';

class FolderList extends StatelessWidget {
  const FolderList({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          final folders = audioProvider.folders;

          if (folders.isEmpty) {
            return const Center(
              child: Text(
                "No folders found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for MiniPlayer
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folderPath = folders.keys.elementAt(index);
              final songCount = folders[folderPath]?.length ?? 0;
              final folderName = p.basename(folderPath);

              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  folderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "$songCount songs",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FolderSongsScreen(
                        folderName: folderName,
                        songs: folders[folderPath]!,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
