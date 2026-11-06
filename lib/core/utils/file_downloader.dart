import 'dart:typed_data';
import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart' as platform;

class FileDownloader {
  static void save({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) {
    platform.downloadFile(bytes, fileName, mimeType);
  }
}

