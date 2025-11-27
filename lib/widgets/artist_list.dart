import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';

class ArtistList extends StatelessWidget {
  const ArtistList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.artists.isEmpty) {
          return const Center(
            child: Text(
              "No artists found",
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: audioProvider.artists.length,
          itemBuilder: (context, index) {
            final artist = audioProvider.artists[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  artist.artist,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "${artist.numberOfTracks} Songs",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
