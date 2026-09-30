import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads generated food photos once and keeps them on disk.
///
/// Image URLs from an image API are temporary, so a saved recipe that only
/// remembered the URL would show a broken photo later. Caching the bytes means
/// saved recipes stay complete, and the photo still renders with no network.
class ImageCacheService {
  ImageCacheService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, File> _memory = <String, File>{};
  Directory? _dir;

  static const Duration _timeout = Duration(seconds: 45);

  File? cached(String? key) {
    if (key == null || key.isEmpty) return null;
    if (_memory.containsKey(key)) return _memory[key];
    final file = File(key);
    if (file.existsSync()) {
      _memory[key] = file;
      return file;
    }
    return null;
  }

  /// Returns a local file for [url], downloading it once. Never throws: on any
  /// failure the caller simply keeps its existing placeholder artwork.
  Future<File?> fetch(String url) async {
    if (url.isEmpty) return null;
    final existing = cached(url);
    if (existing != null) return existing;

    try {
      final res = await _client.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        debugPrint('CookSmart: image fetch failed (${res.statusCode}) $url');
        return null;
      }
      if (res.bodyBytes.length > 12 * 1024 * 1024) {
        debugPrint('CookSmart: image too large, skipping cache');
        return null;
      }

      final dir = await _directory();
      final name = '${url.hashCode.toUnsigned(32).toRadixString(16)}'
          '.${_extensionFor(url, res.headers['content-type'])}';
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(res.bodyBytes, flush: true);
      _memory[url] = file;
      return file;
    } catch (e) {
      debugPrint('CookSmart: image cache error: $e');
      return null;
    }
  }

  Future<Directory> _directory() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}recipe_images');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
    return dir;
  }

  static String _extensionFor(String url, String? contentType) {
    final type = contentType ?? '';
    if (type.contains('png')) return 'png';
    if (type.contains('webp')) return 'webp';
    final dot = url.lastIndexOf('.');
    if (dot != -1 && url.length - dot <= 5) {
      final ext = url.substring(dot + 1).toLowerCase();
      if (RegExp(r'^[a-z0-9]+$').hasMatch(ext)) return ext;
    }
    return 'jpg';
  }

  void dispose() => _client.close();
}
