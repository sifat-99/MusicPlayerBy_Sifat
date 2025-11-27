import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:sifat_audio/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late SettingsProvider _settingsProvider;
  ConcatenatingAudioSource? _playlist;

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
  Map<String, List<SongModel>> _folders = {};
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isShuffleEnabled = false;
  List<String> _favorites = [];
  List<String> _cachedIgnoredPaths = [];
  List<String> _cachedMusicPaths = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<SongModel> get songs => _filteredSongs;
  List<ArtistModel> get artists => _artists;
  List<AlbumModel> get albums => _albums;
  Map<String, List<SongModel>> get folders => _folders;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffleEnabled => _isShuffleEnabled;
  List<String> get favorites => _favorites;
  Duration get duration => _duration;
  Duration get position => _position;
  SongModel? get currentSong =>
      _currentIndex != -1 ? _filteredSongs[_currentIndex] : null;

  AudioProvider() {
    _initAudioPlayer();
    _loadFavorites();
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;

    // Check if ignored paths changed
    bool ignoredPathsChanged = false;
    if (_cachedIgnoredPaths.length != settings.ignoredPaths.length) {
      ignoredPathsChanged = true;
    } else {
      for (int i = 0; i < _cachedIgnoredPaths.length; i++) {
        if (_cachedIgnoredPaths[i] != settings.ignoredPaths[i]) {
          ignoredPathsChanged = true;
          break;
        }
      }
    }

    // Check if music paths changed
    bool musicPathsChanged = false;
    if (_cachedMusicPaths.length != settings.musicPaths.length) {
      musicPathsChanged = true;
    } else {
      for (int i = 0; i < _cachedMusicPaths.length; i++) {
        if (_cachedMusicPaths[i] != settings.musicPaths[i]) {
          musicPathsChanged = true;
          break;
        }
      }
    }

    if (ignoredPathsChanged || musicPathsChanged) {
      _cachedIgnoredPaths = List.from(settings.ignoredPaths);
      _cachedMusicPaths = List.from(settings.musicPaths);
      // Re-fetch songs to apply new ignore rules or scan new paths
      // Use microtask to avoid setState during build if this is called during build
      Future.microtask(() => fetchSongs());
    } else if (_songs.isNotEmpty) {
      // Re-filter songs if minDuration changed (or other filterable settings)
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

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        _currentIndex = index;
        notifyListeners();
      }
    });
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // For Android 13+
      var audioStatus = await Permission.audio.status;
      if (!audioStatus.isGranted) {
        await Permission.audio.request();
      }
    }
    // On macOS, permissions are handled by entitlements and system prompts when accessing files.

    fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchSongs(), fetchArtists(), fetchAlbums()]);
  }

  Future<void> fetchSongs() async {
    // Capture current playing state
    int? currentSongId;
    if (_currentIndex != -1 && _currentIndex < _filteredSongs.length) {
      currentSongId = _filteredSongs[_currentIndex].id;
    }
    final wasPlaying = _isPlaying;
    final currentPos = _audioPlayer.position;

    if (Platform.isMacOS) {
      await _fetchSongsMacOS();
    } else {
      _songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    }

    // Filter out ignored paths
    if (_settingsProvider.ignoredPaths.isNotEmpty) {
      _songs = _songs.where((song) {
        if (song.data.isEmpty) return true;
        for (var ignoredPath in _settingsProvider.ignoredPaths) {
          if (song.data.startsWith(ignoredPath)) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    _filteredSongs = List.from(_songs);
    _groupSongsByFolder();
    await _updatePlaylist(
      preserveSongId: currentSongId,
      preservePosition: currentPos,
      wasPlaying: wasPlaying,
    );
    notifyListeners();
  }

  Future<void> fetchArtists() async {
    if (Platform.isMacOS) {
      _artists = [];
      notifyListeners();
      return;
    }
    _artists = await _audioQuery.queryArtists(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  Future<void> fetchAlbums() async {
    if (Platform.isMacOS) {
      _albums = [];
      notifyListeners();
      return;
    }
    _albums = await _audioQuery.queryAlbums(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    notifyListeners();
  }

  void filterSongs(String query) {
    // Capture current playing state
    int? currentSongId;
    if (_currentIndex != -1 && _currentIndex < _filteredSongs.length) {
      currentSongId = _filteredSongs[_currentIndex].id;
    }
    final wasPlaying = _isPlaying;
    final currentPos = _audioPlayer.position;

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

    _updatePlaylist(
      preserveSongId: currentSongId,
      preservePosition: currentPos,
      wasPlaying: wasPlaying,
    );
    notifyListeners();
  }

  Future<void> _updatePlaylist({
    int? preserveSongId,
    Duration? preservePosition,
    bool wasPlaying = false,
  }) async {
    final audioSources = _filteredSongs.map((song) {
      return AudioSource.uri(
        song.uri != null ? Uri.parse(song.uri!) : Uri.file(song.data),
        tag: MediaItem(
          id: song.id.toString(),
          album: song.album ?? "Unknown Album",
          title: song.title,
          artist: song.artist ?? "Unknown Artist",
          artUri: Uri.parse(
            "content://media/external/audio/media/${song.id}/albumart",
          ),
        ),
      );
    }).toList();

    _playlist = ConcatenatingAudioSource(children: audioSources);

    int initialIndex = 0;
    Duration initialPosition = Duration.zero;
    bool shouldPreserve = false;

    if (preserveSongId != null) {
      final index = _filteredSongs.indexWhere((s) => s.id == preserveSongId);
      if (index != -1) {
        initialIndex = index;
        initialPosition = preservePosition ?? Duration.zero;
        shouldPreserve = true;
      }
    }

    if (shouldPreserve) {
      await _audioPlayer.setAudioSource(
        _playlist!,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
      );
      if (wasPlaying) {
        _audioPlayer.play();
      }
    } else {
      await _audioPlayer.setAudioSource(_playlist!);
    }
  }

  Future<void> playSong(int index) async {
    try {
      // If the playlist hasn't been set or is different (which shouldn't happen if we update on filter),
      // we just seek.
      // But wait, if we just initialized, we might need to set source?
      // _updatePlaylist sets the source.

      await _audioPlayer.seek(Duration.zero, index: index);
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
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> playPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    await _audioPlayer.setShuffleModeEnabled(_isShuffleEnabled);
    notifyListeners();
  }

  bool isFavorite(int id) {
    return _favorites.contains(id.toString());
  }

  Future<void> toggleFavorite(int id) async {
    final String idStr = id.toString();
    if (_favorites.contains(idStr)) {
      _favorites.remove(idStr);
    } else {
      _favorites.add(idStr);
    }
    notifyListeners();
    await _saveFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('favorites') ?? [];
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
  }

  List<SongModel> get favoriteSongs {
    return _songs
        .where((song) => _favorites.contains(song.id.toString()))
        .toList();
  }

  void _groupSongsByFolder() {
    _folders.clear();
    for (var song in _songs) {
      // song.data contains the absolute path
      // We need to be careful if data is null or empty, though usually it's not for valid songs
      if (song.data.isNotEmpty) {
        final directory = p.dirname(song.data);
        // final folderName = p.basename(directory); // Removed unused variable

        // We can use the full path as key to avoid collisions, but display folderName
        // Or just use folderName if we want to group by name (risk of collision)
        // Let's use directory path as key
        if (!_folders.containsKey(directory)) {
          _folders[directory] = [];
        }
        _folders[directory]!.add(song);
      }
    }
    notifyListeners();
  }

  Future<void> _fetchSongsMacOS() async {
    List<SongModel> songs = [];
    // Default to Music directory
    String? home = Platform.environment['HOME'];
    if (home != null) {
      String musicPath = p.join(home, 'Music');
      Directory musicDir = Directory(musicPath);
      if (await musicDir.exists()) {
        await _scanDirectory(musicDir, songs);
      }
    }

    // Scan custom paths
    for (String path in _settingsProvider.musicPaths) {
      Directory customDir = Directory(path);
      if (await customDir.exists()) {
        await _scanDirectory(customDir, songs);
      }
    }

    _songs = songs;
  }

  Future<void> _scanDirectory(Directory dir, List<SongModel> songs) async {
    try {
      List<FileSystemEntity> entities = dir.listSync(recursive: false);
      for (var entity in entities) {
        if (entity is Directory) {
          // Recursive scan
          await _scanDirectory(entity, songs);
        } else if (entity is File) {
          String? mimeType = lookupMimeType(entity.path);
          if (mimeType != null && mimeType.startsWith('audio/')) {
            // Create a SongModel manually
            // Note: Metadata extraction is limited without a proper tag reader.
            // We'll use filename as title for now.
            String filename = p.basename(entity.path);
            String title = p.basenameWithoutExtension(entity.path);

            // Generate a pseudo-ID based on path hash
            int id = entity.path.hashCode;

            songs.add(
              SongModel({
                '_id': id,
                '_data': entity.path,
                '_display_name': filename,
                'title': title,
                'artist': 'Unknown Artist',
                'album': 'Unknown Album',
                'duration': 0, // Duration requires reading the file
                'is_music': true,
                '_uri': Uri.file(entity.path).toString(),
              }),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error scanning directory: $e");
    }
  }
}
