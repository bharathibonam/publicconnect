import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResumableUploadService {
  static final _supabase = Supabase.instance.client;

  /// Uploads binary file bytes to Supabase Storage using chunked resumable upload
  static Future<String?> uploadFileInChunks({
    required String bucketName,
    required String destinationPath,
    required Uint8List fileBytes,
    required String contentType,
    Function(double progress)? onProgress,
  }) async {
    final int totalSize = fileBytes.length;
    
    // File size validation (limit to 100MB for safe memory operations in flutter web demo)
    if (totalSize > 100 * 1024 * 1024) {
      throw Exception('File size exceeds the maximum limit of 100MB.');
    }

    debugPrint('Starting chunked upload of size: $totalSize bytes to $destinationPath...');
    
    // Chunk size: 2MB (minimum recommended size for chunked streams)
    final int chunkSize = 2 * 1024 * 1024;
    int offset = 0;
    int attempt = 0;
    const int maxRetries = 3;

    try {
      while (offset < totalSize) {
        final int end = (offset + chunkSize < totalSize) ? offset + chunkSize : totalSize;
        final Uint8List chunk = fileBytes.sublist(offset, end);
        
        bool chunkUploaded = false;
        attempt = 0;

        while (!chunkUploaded && attempt < maxRetries) {
          try {
            // Upload chunk using upsert/append logic or standard chunk uploading
            // In a production environment with standard Supabase Storage, resumable uploads use TUS protocol.
            // For simple implementation without third-party TUS client, we simulate the resumable chunks:
            if (offset == 0) {
              // Write first chunk
              await _supabase.storage.from(bucketName).uploadBinary(
                    destinationPath,
                    chunk,
                    fileOptions: FileOptions(upsert: true, contentType: contentType),
                  );
            } else {
              // Append subsequent chunks or overwrite with completed stream
              // Note: Standard Supabase Storage API supports upsert but not append directly.
              // To simulate real chunked resumable upload in local environment:
              final Uint8List accumulatedBytes = fileBytes.sublist(0, end);
              await _supabase.storage.from(bucketName).uploadBinary(
                    destinationPath,
                    accumulatedBytes,
                    fileOptions: FileOptions(upsert: true, contentType: contentType),
                  );
            }
            
            chunkUploaded = true;
            offset = end;
            
            if (onProgress != null) {
              onProgress(offset / totalSize);
            }
          } catch (e) {
            attempt++;
            debugPrint('Failed uploading chunk at offset $offset (Attempt $attempt/$maxRetries): $e');
            if (attempt >= maxRetries) {
              throw Exception('Chunk upload failed after $maxRetries attempts at offset $offset: $e');
            }
            // Wait before retry
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      }
      
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(destinationPath);
      debugPrint('Resumable upload completed successfully. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Resumable upload failed: $e');
      rethrow;
    }
  }
}
