import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongTile extends StatefulWidget {
  final SongModel song;
  final VoidCallback onTap;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isPlaying = false,
  });

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isPlaying
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : _isHovering
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: widget.onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Hero(
              tag: 'list_artwork_${widget.song.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: QueryArtworkWidget(
                  id: widget.song.id,
                  type: ArtworkType.AUDIO,
                  keepOldArtwork: true,
                  nullArtworkWidget: Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            widget.song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: widget.isPlaying
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.song.artist ?? "Unknown Artist",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          trailing: widget.isPlaying
              ? Icon(
                  Icons.graphic_eq,
                  color: Theme.of(context).colorScheme.primary,
                )
              : _isHovering
              ? Icon(Icons.play_arrow_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
