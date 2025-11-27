import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:sifat_audio/providers/settings_provider.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late SettingsProvider _settingsProvider;

  // Audio Effects
  double _speed = 1.0;
  double _pitch = 1.0;

  double get speed => _speed;
  double get pitch => _pitch;

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _audioPlayer.setPitch(pitch);
    notifyListeners();
  }

  List<SongModel> _songs = [];
  List<SongModel> _filteredSongs = [];
  List<ArtistModel> _artists = [];
  List<AlbumModel> _albums = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<SongModel> get songs => _filteredSongs;
  List<ArtistModel> get artists => _artists;
  List<AlbumModel> get albums => _albums;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  SongModel? get currentSong =>
      _currentIndex != -1 ? _filteredSongs[_currentIndex] : null;

  AudioProvider() {
    _initAudioPlayer();
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    // Re-filter songs if minDuration changed
    if (_songs.isNotEmpty) {
      filterSongs(""); // Re-apply filter
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> requestPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // For Android 13+
    var audioStatus = await Permission.audio.status;
    if (!audioStatus.isGranted) {
      await Permission.audio.request();
    }

    fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchSongs(), fetchArtists(), fetchAlbums()]);
  }

  Future<void> fetchSongs() async {
    _songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    _filteredSongs = List.from(_songs);
    notifyListeners();
  }

  Future<void> fetchArtists() async {
    _artists = await _audioQuery.queryArtists(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  Future<void> fetchAlbums() async {
    _albums = await _audioQuery.queryAlbums(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  void filterSongs(String query) {
    // Apply min duration filter first
    var tempSongs = _songs.where((song) {
      return song.duration != null &&
          song.duration! >= (_settingsProvider.minDuration * 1000);
    }).toList();

    if (query.isEmpty) {
      _filteredSongs = List.from(tempSongs);
    } else {
      _filteredSongs = tempSongs.where((song) {
        return song.title.toLowerCase().contains(query.toLowerCase()) ||
            (song.artist?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> playSong(int index) async {
    try {
      _currentIndex = index;
      var song = _filteredSongs[index];

      // Create MediaItem for notification
      final mediaItem = MediaItem(
        id: song.id.toString(),
        album: song.album ?? "Unknown Album",
        title: song.title,
        artist: song.artist ?? "Unknown Artist",
        artUri: Uri.parse(
          "content://media/external/audio/media/${song.id}/albumart",
        ),
      );

      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(song.uri!), tag: mediaItem),
      );
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> playNext() async {
    if (_currentIndex < _filteredSongs.length - 1) {
      await playSong(_currentIndex + 1);
    } else {
      // Loop back to start or stop? Let's loop for now or just stop.
      // Simple player: loop to first if at end.
      if (_filteredSongs.isNotEmpty) {
        await playSong(0);
      }
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      await playSong(_currentIndex - 1);
    } else {
      if (_filteredSongs.isNotEmpty) {
        await playSong(_filteredSongs.length - 1);
      }
    }
  }
}
