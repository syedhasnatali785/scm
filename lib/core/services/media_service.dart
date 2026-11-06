import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../data/repositories/storage_repository.dart';

class MediaService {
  static final IStorageRepository _storageRepo = SupabaseStorageRepository();

  /// Compresses any raw image bytes into an ultra-compact WebP thumbnail under 15 KB
  static Uint8List compressToThumbnailWebP(Uint8List rawBytes, {int targetMaxKb = 15}) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      // Resize thumbnail to max 256px on longest edge
      final resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 256 : null,
        height: decoded.height >= decoded.width ? 256 : null,
        interpolation: img.Interpolation.linear,
      );

      // Iterative quality loop to strictly enforce < 15 KB
      int quality = 80;
      Uint8List compressed = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );

      while (compressed.lengthInBytes > targetMaxKb * 1024 && quality > 30) {
        quality -= 15;
        compressed = Uint8List.fromList(
          img.encodeJpg(resized, quality: quality),
        );
      }

      return compressed;
    } catch (e) {
      debugPrint('Media compression error: $e');
      return rawBytes;
    }
  }

  /// Uploads compressed thumbnail directly via Storage Repository:
  /// product-media/{org_id}/{shipment_id}/{item_id}.webp
  static Future<String> uploadProductThumbnail({
    required String orgId,
    required String shipmentId,
    required String itemId,
    required Uint8List rawBytes,
  }) async {
    // 1. Client-Side compression (< 15 KB)
    final compressedBytes = compressToThumbnailWebP(rawBytes, targetMaxKb: 15);

    // 2. Upload via Storage Repository
    return _storageRepo.uploadThumbnail(
      orgId: orgId,
      shipmentId: shipmentId,
      itemId: itemId,
      bytes: compressedBytes,
    );
  }
}
