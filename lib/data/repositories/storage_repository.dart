import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_config.dart';

abstract class IStorageRepository {
  Future<String> uploadThumbnail({
    required String orgId,
    required String shipmentId,
    required String itemId,
    required Uint8List bytes,
  });
}

class SupabaseStorageRepository implements IStorageRepository {
  @override
  Future<String> uploadThumbnail({
    required String orgId,
    required String shipmentId,
    required String itemId,
    required Uint8List bytes,
  }) async {
    final storagePath = '$orgId/$shipmentId/$itemId.jpg';

    if (SupabaseConfig.isInitialized && !SupabaseConfig.isMockMode) {
      try {
        final client = SupabaseConfig.client;
        await client.storage.from('product-media').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        return client.storage.from('product-media').getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Supabase storage upload error (using local data URI fallback): $e');
      }
    }

    // Offline data URI fallback
    final base64Str = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64Str';
  }
}
