import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _showLyrics = false;
  bool _autoPlay = true;
  int _minDuration = 0; // Seconds
  String _audioQuality = 'High';
  List<String> _ignoredPaths = [];
  List<String> _musicPaths = [];

  double _fontSize = 1.0;

  bool get showLyrics => _showLyrics;
  bool get autoPlay => _autoPlay;
  int get minDuration => _minDuration;
  String get audioQuality => _audioQuality;
  double get fontSize => _fontSize;
  List<String> get ignoredPaths => _ignoredPaths;
  List<String> get musicPaths => _musicPaths;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showLyrics = prefs.getBool('showLyrics') ?? false;
    _autoPlay = prefs.getBool('autoPlay') ?? true;
    _minDuration = prefs.getInt('minDuration') ?? 0;
    _audioQuality = prefs.getString('audioQuality') ?? 'High';
    _fontSize = prefs.getDouble('fontSize') ?? 1.0;
    _ignoredPaths = prefs.getStringList('ignoredPaths') ?? [];
    _musicPaths = prefs.getStringList('musicPaths') ?? [];
    notifyListeners();
  }

  Future<void> setShowLyrics(bool value) async {
    _showLyrics = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showLyrics', value);
  }

  Future<void> setAutoPlay(bool value) async {
    _autoPlay = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoPlay', value);
  }

  Future<void> setMinDuration(int seconds) async {
    _minDuration = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minDuration', seconds);
  }

  Future<void> setAudioQuality(String quality) async {
    _audioQuality = quality;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audioQuality', quality);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
  }

  Future<void> addIgnoredPath(String path) async {
    if (!_ignoredPaths.contains(path)) {
      _ignoredPaths.add(path);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('ignoredPaths', _ignoredPaths);
    }
  }

  Future<void> removeIgnoredPath(String path) async {
    _ignoredPaths.remove(path);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ignoredPaths', _ignoredPaths);
  }

  Future<void> addMusicPath(String path) async {
    if (!_musicPaths.contains(path)) {
      _musicPaths.add(path);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('musicPaths', _musicPaths);
    }
  }

  Future<void> removeMusicPath(String path) async {
    _musicPaths.remove(path);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('musicPaths', _musicPaths);
  }
}
