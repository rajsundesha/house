import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> getFileSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  static String getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }

  static bool isImageFile(String fileName) {
    final mimeType = lookupMimeType(fileName);
    return mimeType?.startsWith('image/') ?? false;
  }

  static Future<File> saveFile(
    String fileName,
    List<int> bytes, {
    String? directory,
  }) async {
    final dir = directory ?? (await getApplicationDocumentsDirectory()).path;
    final file = File('$dir/$fileName');
    return await file.writeAsBytes(bytes);
  }
}
