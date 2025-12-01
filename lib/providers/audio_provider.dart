import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:sifat_audio/providers/settings_provider.dart';
import 'package:sifat_audio/services/youtube_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final YouTubeService _youtubeService = YouTubeService();
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
  SongModel? _streamSong;

  SongModel? get currentSong {
    if (_streamSong != null) return _streamSong;
    if (_currentIndex != -1 && _currentIndex < _filteredSongs.length) {
      return _filteredSongs[_currentIndex];
    }
    return null;
  }

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

    if (Platform.isIOS) {
      var mediaLibraryStatus = await Permission.mediaLibrary.status;
      if (!mediaLibraryStatus.isGranted) {
        await Permission.mediaLibrary.request();
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
      // Query system library
      var systemSongs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Scan app documents for downloaded files (iOS/Android)
      List<SongModel> localDownloads = [];
      try {
        final dir = await getApplicationDocumentsDirectory();
        if (await dir.exists()) {
          await _scanDirectory(dir, localDownloads);
        }

        // Android: Also scan the public Music/Zofio directory
        if (Platform.isAndroid) {
          final zofioDir = Directory('/storage/emulated/0/Music/Zofio');
          if (await zofioDir.exists()) {
            await _scanDirectory(zofioDir, localDownloads);
          }
        }
      } catch (e) {
        debugPrint("Error scanning local files: $e");
      }

      // Merge system songs and local downloads
      // Avoid duplicates based on path
      final systemPaths = systemSongs.map((s) => s.data).toSet();
      for (var song in localDownloads) {
        if (!systemPaths.contains(song.data)) {
          systemSongs.add(song);
        }
      }

      _songs = systemSongs;
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
    _streamSong = null; // Clear stream song when updating playlist
    final audioSources = _filteredSongs
        .where((song) {
          // Ensure we have a valid source
          return (song.uri != null && song.uri!.isNotEmpty) ||
              song.data.isNotEmpty;
        })
        .map((song) {
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
        })
        .toList();

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

    try {
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
    } catch (e) {
      debugPrint("Error updating playlist: $e");
      // Ignore "Loading interrupted" errors as they are expected when rapid updates occur
    }
  }

  Future<void> playSong(int index) async {
    try {
      _streamSong = null; // Ensure we are not in stream mode

      // Check if we need to restore the full playlist (e.g. after playing a single stream)
      if (_playlist == null || _playlist!.length != _filteredSongs.length) {
        await _updatePlaylist();
      }

      await _audioPlayer.seek(Duration.zero, index: index);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  Future<void> playUrl(
    String url,
    String title,
    String artist,
    String artworkUrl,
  ) async {
    try {
      // Extract Video ID if a full URL is passed
      String videoId = url;
      final RegExp idRegExp = RegExp(r'(?<=v=)[a-zA-Z0-9_-]{11}');
      final RegExp shortIdRegExp = RegExp(r'(?<=youtu\.be\/)[a-zA-Z0-9_-]{11}');

      if (url.contains('http')) {
        if (idRegExp.hasMatch(url)) {
          videoId = idRegExp.firstMatch(url)!.group(0)!;
        } else if (shortIdRegExp.hasMatch(url)) {
          videoId = shortIdRegExp.firstMatch(url)!.group(0)!;
        }
      }

      // INSTANT UI UPDATE: Set the song model immediately so the UI shows it
      _streamSong = SongModel({
        '_id': videoId.hashCode,
        'title': title,
        'artist': artist,
        '_data': '', // Placeholder, will be updated
        '_uri': '', // Placeholder
        'album': 'YouTube Music',
        'duration': 0,
        'is_music': true,
        'artwork_url': artworkUrl,
      });
      notifyListeners();

      // Stop current playback
      await _audioPlayer.stop();

      // Ensure proxy is started
      await _youtubeService.startProxy();

      // Fetch stream info and cache it
      final streamInfo = await _youtubeService.getBestStreamInfo(videoId);

      if (streamInfo == null) {
        debugPrint("Error: Could not resolve audio stream for $videoId");
        return;
      }

      _youtubeService.cacheStreamInfo(videoId, streamInfo);

      // Get proxy URL
      final proxyUrl = _youtubeService.getProxyUrl(videoId);

      // Update the model with the actual proxy URL
      _streamSong = SongModel({
        '_id': videoId.hashCode,
        'title': title,
        'artist': artist,
        '_data': proxyUrl,
        '_uri': proxyUrl,
        'album': 'YouTube Music',
        'duration': 0,
        'is_music': true,
        'artwork_url': artworkUrl,
      });

      final source = AudioSource.uri(
        Uri.parse(proxyUrl),
        tag: MediaItem(
          id: videoId,
          album: "YouTube Music",
          title: title,
          artist: artist,
          artUri: Uri.parse(artworkUrl),
        ),
      );

      // We are playing a single stream, so we replace the playlist
      _playlist = ConcatenatingAudioSource(children: [source]);
      await _audioPlayer.setAudioSource(_playlist!);
      await _audioPlayer.play();

      // Update current index manually since it's a new playlist
      _currentIndex = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Error playing URL: $e");
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

  Future<void> stop() async {
    await _audioPlayer.stop();
    _streamSong = null;
    _currentIndex = -1; // Reset index to ensure currentSong returns null
    notifyListeners();
  }

  bool get isStream => _streamSong != null;

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
          // Check file size to avoid empty/corrupt downloads
          if (await entity.length() < 1024 * 100) {
            continue;
          }

          String? mimeType = lookupMimeType(entity.path);
          // Allow audio/* and video/webm (often used for audio-only webm files) and video/mp4
          if (mimeType != null &&
              (mimeType.startsWith('audio/') ||
                  mimeType == 'video/webm' ||
                  mimeType == 'video/mp4')) {
            // Create a SongModel manually
            String filename = p.basename(entity.path);
            String title = p.basenameWithoutExtension(entity.path);
            int id = entity.path.hashCode;

            songs.add(
              SongModel({
                '_id': id,
                '_data': entity.path,
                '_display_name': filename,
                'title': title,
                'artist': 'Unknown Artist',
                'album': 'Unknown Album',
                'duration': 0,
                'is_music': true,
                // '_uri': Let _updatePlaylist handle it via Uri.file(_data)
              }),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error scanning directory: $e");
    }
  }

  final Set<String> _downloadingIds = {};

  bool isDownloading(String id) => _downloadingIds.contains(id);

  Future<void> downloadSongFromStream(
    Stream<List<int>> stream,
    String title,
    String artist, {
    String ext = 'm4a',
    String? id,
  }) async {
    if (id != null) {
      _downloadingIds.add(id);
      notifyListeners();
    }
    try {
      // Get directory
      Directory? dir;
      if (Platform.isAndroid) {
        // Request permissions
        if (await Permission.manageExternalStorage.request().isGranted) {
          // Android 11+ with All Files Access
        } else if (await Permission.storage.request().isGranted) {
          // Older Android or partial access
        } else {
          // Permission denied
          // Try to request manageExternalStorage again if it's permanently denied or restricted
          if (await Permission.manageExternalStorage.isPermanentlyDenied) {
            openAppSettings();
            return;
          }
        }

        dir = Directory('/storage/emulated/0/Music/Zofio');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filename =
          "${title.replaceAll(RegExp(r'[^\w\s]+'), '')} - $artist.$ext";
      final savePath = p.join(dir.path, filename);
      final file = File(savePath);

      // Write stream to file
      final sink = file.openWrite();
      await stream.pipe(sink);
      await sink.close();

      // Verify download
      if (await file.length() == 0) {
        debugPrint("Download failed: File is empty");
        await file.delete();
      } else {
        debugPrint("Downloaded to $savePath (${await file.length()} bytes)");
        // Refresh library
        await fetchSongs();
      }
    } catch (e) {
      debugPrint("Error downloading: $e");
    } finally {
      if (id != null) {
        _downloadingIds.remove(id);
        notifyListeners();
      }
    }
  }

  // Deprecated: Use downloadSongFromStream for better reliability with YouTube
  Future<void> downloadSong(
    String url,
    String title,
    String artist, {
    String ext = 'm4a',
  }) async {
    try {
      // Get directory
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Music/Zofio');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filename =
          "${title.replaceAll(RegExp(r'[^\w\s]+'), '')} - $artist.$ext";
      final savePath = p.join(dir.path, filename);

      // Download using HttpClient
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      final file = File(savePath);
      await response.pipe(file.openWrite());

      debugPrint("Downloaded to $savePath");

      if (await file.length() == 0) {
        await file.delete();
      } else {
        await fetchSongs();
      }
    } catch (e) {
      debugPrint("Error downloading: $e");
    }
  }
}
