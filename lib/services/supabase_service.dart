// supabase_service.dart
import 'dart:typed_data';
import 'package:supabase/supabase.dart';
import 'supabase_config.dart';

class SupabaseService {
  static final SupabaseClient client = SupabaseClient(
    SupabaseConfig.supabaseUrl,
    SupabaseConfig.supabaseAnonKey,
  );

  // Upload file to Supabase Storage
  static Future<String> uploadFile({
    required String bucketName,
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
  }) async {
    try {
      // Upload the file
      await client.storage.from(bucketName).uploadBinary(fileName, fileBytes,
          fileOptions: FileOptions(
            contentType: fileType,
            upsert: true,
          ));

      // Get public URL
      final publicUrl = client.storage.from(bucketName).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Check if file exists
  static Future<bool> fileExists(String bucketName, String fileName) async {
    try {
      final response =
          await client.storage.from(bucketName).list(path: fileName);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
