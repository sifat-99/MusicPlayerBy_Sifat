import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

class YouTubeService {
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  Future<List<yt.Video>> searchSongs(String query) async {
    try {
      final result = await _yt.search.search(query);
      return result.whereType<yt.Video>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<yt.Video>> getTrendingSongs() async {
    try {
      // Simulate trending by searching for global hits
      final result = await _yt.search.search("Top Global Hits Music");
      return result.whereType<yt.Video>().take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<yt.Video>> getQuickPicks() async {
    try {
      // Simulate quick picks with a generic mix
      final result = await _yt.search.search("Music Recommendations Mix");
      return result.whereType<yt.Video>().take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<StreamInfo?> getBestStreamInfo(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Prefer muxed streams (video+audio) as audio-only streams are currently being throttled/blocked (403)
      // Muxed streams seem to work reliably (200 OK)
      var streams = manifest.muxed;
      if (streams.isNotEmpty) {
        final stream = streams.withHighestBitrate();
        return stream;
      }

      // Fallback to audio-only if no muxed streams (unlikely)
      if (Platform.isIOS || Platform.isMacOS) {
        var audioStreams = manifest.audioOnly;
        var mp4Streams = audioStreams.where(
          (s) => s.container == yt.StreamContainer.mp4,
        );
        return mp4Streams.isNotEmpty
            ? mp4Streams.withHighestBitrate()
            : audioStreams.withHighestBitrate();
      } else {
        return manifest.audioOnly.withHighestBitrate();
      }
    } catch (e) {
      debugPrint("Error in getBestStreamInfo: $e");
      return null;
    }
  }

  Future<String?> getAudioUrl(String videoId) async {
    try {
      final info = await getBestStreamInfo(videoId);
      return info?.url.toString();
    } catch (e) {
      return null;
    }
  }

  Future<({String url, String ext})?> getDownloadStreamInfo(
    String videoId,
  ) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Prefer muxed streams (video+audio) to avoid 403 errors
      var streams = manifest.muxed;
      if (streams.isNotEmpty) {
        final stream = streams.withHighestBitrate();
        return (
          url: stream.url.toString(),
          ext: stream.container.name == 'mp4' ? 'mp4' : 'webm',
        );
      }

      // Fallback to audio-only
      var audioStreams = manifest.audioOnly;
      if (Platform.isIOS || Platform.isMacOS) {
        var mp4Streams = audioStreams.where(
          (s) => s.container == yt.StreamContainer.mp4,
        );
        var stream = mp4Streams.isNotEmpty
            ? mp4Streams.withHighestBitrate()
            : audioStreams.withHighestBitrate();
        return (
          url: stream.url.toString(),
          ext: stream.container.name == 'mp4' ? 'm4a' : 'webm',
        );
      } else {
        var stream = audioStreams.withHighestBitrate();
        return (
          url: stream.url.toString(),
          ext: stream.container.name == 'mp4' ? 'm4a' : 'webm',
        );
      }
    } catch (e) {
      return null;
    }
  }

  Future<({Stream<List<int>> stream, String ext})?> getDownloadStream(
    String videoId,
  ) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      StreamInfo? streamInfo;

      // Prefer muxed streams (video+audio) to avoid 403 errors
      var streams = manifest.muxed;
      if (streams.isNotEmpty) {
        streamInfo = streams.withHighestBitrate();
      } else {
        // Fallback to audio-only
        var audioStreams = manifest.audioOnly;
        if (Platform.isIOS || Platform.isMacOS) {
          var mp4Streams = audioStreams.where(
            (s) => s.container == yt.StreamContainer.mp4,
          );
          streamInfo = mp4Streams.isNotEmpty
              ? mp4Streams.withHighestBitrate()
              : audioStreams.withHighestBitrate();
        } else {
          streamInfo = audioStreams.withHighestBitrate();
        }
      }

      return (
        stream: _yt.videos.streamsClient.get(streamInfo),
        // If muxed, it's likely mp4 or webm (video). If audio-only mp4, we use m4a.
        // For simplicity, if it's mp4 container, we can save as mp4 (since it might have video now)
        // or m4a if we want to pretend it's audio.
        // Since we are using muxed streams which HAVE video, saving as .m4a might be misleading but players handle it.
        // However, to be safe, let's use .mp4 if it is muxed/mp4.
        ext: streamInfo.container.name == 'mp4' ? 'mp4' : 'webm',
      );
    } catch (e) {
      return null;
    }
  }

  final Map<String, StreamInfo> _streamInfoCache = {};

  void cacheStreamInfo(String videoId, StreamInfo info) {
    _streamInfoCache[videoId] = info;
  }

  HttpServer? _server;

  Future<void> startProxy() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((request) async {
      final videoId = request.uri.pathSegments.last;
      debugPrint("Proxy: Received request for $videoId");

      try {
        StreamInfo? streamInfo;

        // Check cache first
        if (_streamInfoCache.containsKey(videoId)) {
          streamInfo = _streamInfoCache[videoId];
          debugPrint("Proxy: Cache hit for $videoId");
        } else {
          debugPrint("Proxy: Cache miss for $videoId, fetching...");
          // Fallback to fetching
          final manifest = await _yt.videos.streamsClient.getManifest(videoId);
          // Prefer muxed
          var streams = manifest.muxed;
          if (streams.isNotEmpty) {
            streamInfo = streams.withHighestBitrate();
          } else {
            streamInfo = manifest.audioOnly.withHighestBitrate();
          }
        }

        if (streamInfo == null) {
          debugPrint("Proxy: Stream info not found for $videoId");
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        debugPrint("Proxy: Starting stream for $videoId");
        final stream = _yt.videos.streamsClient.get(streamInfo);

        request.response.headers.contentType = ContentType.parse(
          streamInfo.container.name == 'mp4' ? 'audio/mp4' : 'audio/webm',
        );
        // Disable range support for now to avoid confusion
        request.response.headers.set('Accept-Ranges', 'none');
        request.response.statusCode = HttpStatus.ok;

        await request.response.addStream(stream);
        debugPrint("Proxy: Stream finished for $videoId");
        await request.response.close();
      } catch (e) {
        debugPrint("Proxy Error for $videoId: $e");
        // Only try to send error if headers haven't been sent
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (_) {}
      }
    });
  }

  String getProxyUrl(String videoId) {
    if (_server == null) throw Exception("Proxy not started");
    return 'http://${_server!.address.address}:${_server!.port}/$videoId';
  }

  void dispose() {
    _server?.close();
    _yt.close();
  }
}
