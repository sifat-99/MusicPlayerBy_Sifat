import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _repoOwner = 'sifat-99';
  static const String _repoName = 'MusicPlayerBy_Sifat';

  /// Checks if a new version is available.
  /// Returns the latest version string if available, null otherwise.
  static Future<String?> checkForUpdate() async {
    try {
      final currentVersion = await _getCurrentVersion();
      final latestVersion = await _getLatestVersionFromGitHub();

      if (latestVersion != null &&
          _isUpdateAvailable(currentVersion, latestVersion)) {
        return latestVersion;
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
    return null;
  }

  static Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    print(packageInfo.version);
    return packageInfo.version;
  }

  static Future<String?> _getLatestVersionFromGitHub() async {
    final url = Uri.parse(
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tagName = data['tag_name'] as String;
      // Remove 'v' prefix if present
      return tagName.startsWith('v') ? tagName.substring(1) : tagName;
    }
    return null;
  }

  static bool _isUpdateAvailable(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      final latestPart = latestParts[i];
      final currentPart = i < currentParts.length ? currentParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  static Future<void> launchUpdateUrl() async {
    final url = Uri.parse(
      'https://github.com/$_repoOwner/$_repoName/releases/latest',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}
