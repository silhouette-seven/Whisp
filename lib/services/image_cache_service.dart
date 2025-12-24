import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'database_helper.dart';

class ImageCacheService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String> getCachedImagePath(String url) async {
    if (url.isEmpty) return '';

    try {
      // 1. Check database for local path
      final localPath = await _dbHelper.getLocalPath(url);

      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          return localPath;
        }
      }

      // 2. Download if not found or file missing
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();

        // Create a unique filename based on the URL or timestamp
        // Using a hash of the URL or just a timestamp + random suffix
        final filename =
            '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.jpg';
        final filePath = path.join(directory.path, filename);

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // 3. Save to database
        await _dbHelper.insertImage(url, filePath);

        return filePath;
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      print('Error caching image: $e');
      // Return original URL or empty string on failure,
      // but the caller expects a local path.
      // If we fail to cache, we might just have to return the URL
      // and let the UI handle it (e.g. using NetworkImage as fallback),
      // BUT the requirement is to use local storage.
      // For now, let's return the URL so the UI can decide what to do (fallback).
      return url;
    }
  }

  // Helper to check if the returned path is a local file or remote URL
  bool isLocalFile(String path) {
    return !path.startsWith('http');
  }
}
