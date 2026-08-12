import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhisperService {
  /// Primary Production Endpoint
  static const String _prodEndpoint = 'https://smartgov.quantexintelsystems.com/api/transcribe';
  
  /// Get target API endpoint safely
  static String get activeEndpoint {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('smartgov.quantexintelsystems.com') || (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1')) {
        return _prodEndpoint;
      }
    }
    return _prodEndpoint;
  }

  /// Transcribe raw recorded audio using self-hosted faster-whisper API
  static Future<Map<String, dynamic>> transcribeAudio({
    required Uint8List audioBytes,
    String? language,
  }) async {
    if (audioBytes.isEmpty || audioBytes.length < 800) {
      debugPrint('[WhisperService] ERROR: Audio bytes empty or < 800 bytes');
      return {
        'success': false,
        'error': 'No speech detected. Please speak again.',
      };
    }

    final endpoint = activeEndpoint;

    // Normalize language (en_IN -> en, te_IN -> te)
    final langCode = (language == 'te_IN' || language == 'te')
        ? 'te'
        : (language == 'en_IN' || language == 'en')
            ? 'en'
            : 'auto';

    debugPrint('[WhisperService] Request URL: $endpoint');
    debugPrint('[WhisperService] HTTP method: POST');
    debugPrint('[WhisperService] Audio bytes: ${audioBytes.length}');
    debugPrint('[WhisperService] MIME type: audio/webm');
    debugPrint('[WhisperService] Language: $langCode');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Accept'] = 'application/json';

      final multipartFile = http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'recording.webm',
      );
      request.files.add(multipartFile);

      request.fields['language'] = langCode;

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[WhisperService] HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final text = (data['text'] ?? '').toString().trim();
          if (text.isNotEmpty) {
            debugPrint('[WhisperService] Response received');
            debugPrint('[WhisperService] Transcript length: ${text.length}');
            return {
              'success': true,
              'text': text,
              'language': data['language'] ?? langCode,
            };
          }
        }
        return {
          'success': false,
          'error': data['error'] ?? 'No speech detected. Please speak again.',
        };
      } else if (response.statusCode == 400) {
        return {'success': false, 'error': 'Invalid audio request. Please speak again.'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Whisper transcription endpoint not found (404).'};
      } else if (response.statusCode == 405) {
        return {'success': false, 'error': 'Whisper API method not allowed (405).'};
      } else if (response.statusCode == 413) {
        return {'success': false, 'error': 'Audio file is too large (413).'};
      } else if (response.statusCode >= 500) {
        return {'success': false, 'error': 'Whisper server error (${response.statusCode}). Please try again.'};
      } else {
        return {'success': false, 'error': 'Voice transcription service error (${response.statusCode}).'};
      }
    } on TimeoutException {
      debugPrint('[WhisperService] TimeoutException');
      return {'success': false, 'error': 'Whisper transcription timed out. Please try again.'};
    } catch (e) {
      debugPrint('[WhisperService] Exception: $e');
      return {'success': false, 'error': 'Unable to connect to the Whisper transcription server.'};
    }
  }
}
