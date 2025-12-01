import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: audioProvider.artists.length,
          itemBuilder: (context, index) {
            final artist = audioProvider.artists[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: QueryArtworkWidget(
                    id: artist.id,
                    type: ArtworkType.ARTIST,
                    keepOldArtwork: true,
                    nullArtworkWidget: const Icon(
                      Icons.person,
                      color: Colors.white54,
                      size: 30,
                    ),
                  ),
                ),
              ),
              title: Text(
                artist.artist,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "${artist.numberOfTracks} Songs",
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              onTap: () {
                // TODO: Navigate to Artist Details
              },
            );
          },
        );
      },
    );
  }
}
