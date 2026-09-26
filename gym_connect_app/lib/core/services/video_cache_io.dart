import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'video_cache_manager.dart';

VideoCacheManager createVideoCacheManager() => VideoCacheIO();

class VideoCacheIO implements VideoCacheManager {
  static const String _cacheFolder = 'exercise_videos';
  Directory? _cacheDir;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final baseDir = await getApplicationCacheDirectory();
    final dir = Directory('${baseDir.path}/$_cacheFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _generateFilename(String url) {
    try {
      final uri = Uri.parse(url);
      final seg = uri.pathSegments;
      if (seg.isNotEmpty) {
        final last = seg.last;
        if (last.contains('.')) {
          final clean = last.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
          return clean;
        }
      }
    } catch (_) {}

    // Deterministic hash based on URL bytes
    final bytes = utf8.encode(url);
    int hash = 5381;
    for (final b in bytes) {
      hash = ((hash << 5) + hash) + b;
    }
    return 'video_${hash.abs()}.mp4';
  }

  @override
  Future<String> getOrCacheVideo(
    String remoteUrl, {
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  }) async {
    final cleanUrl = remoteUrl.trim();
    if (cleanUrl.isEmpty) return cleanUrl;

    try {
      final dir = await _getCacheDirectory();
      final filename = _generateFilename(cleanUrl);
      final targetFile = File('${dir.path}/$filename');

      // 1. Cache HIT: File already downloaded and valid
      if (await targetFile.exists()) {
        final len = await targetFile.length();
        if (len > 5000) {
          debugPrint('VideoCacheManager [CACHE HIT]: $filename (${(len / 1024).toStringAsFixed(1)} KB) - 0 API calls used!');
          if (onProgress != null) onProgress(1.0);
          return targetFile.path;
        } else {
          // Incomplete or corrupted file, remove and re-download
          await targetFile.delete();
        }
      }

      // 2. Cache MISS: Download file once to cache directory
      debugPrint('VideoCacheManager [CACHE MISS]: Downloading $cleanUrl to local storage...');
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(cleanUrl));
      if (headers != null) {
        request.headers.addAll(headers);
      }

      final response = await client.send(request);
      if (response.statusCode != 200 && response.statusCode != 206) {
        debugPrint('VideoCacheManager download failed with status ${response.statusCode}');
        client.close();
        return cleanUrl;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final tempFile = File('${targetFile.path}.tmp');
      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      // Rename temp file to target file atomically
      if (await tempFile.exists()) {
        await tempFile.rename(targetFile.path);
        debugPrint('VideoCacheManager [SAVED TO DISK]: ${targetFile.path} (${(receivedBytes / 1024).toStringAsFixed(1)} KB)');
        return targetFile.path;
      }

      return cleanUrl;
    } catch (e) {
      debugPrint('VideoCacheManager error caching video: $e, falling back to remote URL');
      return cleanUrl;
    }
  }

  @override
  Future<bool> isVideoCached(String remoteUrl) async {
    try {
      final dir = await _getCacheDirectory();
      final filename = _generateFilename(remoteUrl);
      final targetFile = File('${dir.path}/$filename');
      if (await targetFile.exists()) {
        return (await targetFile.length()) > 5000;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<int> getCacheSizeBytes() async {
    try {
      final dir = await _getCacheDirectory();
      int total = 0;
      final entities = dir.listSync();
      for (final e in entities) {
        if (e is File) {
          total += e.lengthSync();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final dir = await _getCacheDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('VideoCacheManager clearCache error: $e');
    }
  }
}
