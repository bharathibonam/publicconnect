import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  /// Active Multimodal Audio Gemini Models ordered by capacity and rate limits
  static const List<String> _geminiModels = [
    'gemini-3.5-flash',
    'gemini-flash-latest',
    'gemini-3.6-flash',
  ];

  static Future<String> _getGeminiKey() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('mla_social_tokens')
          .select('access_token')
          .eq('platform', 'gemini')
          .maybeSingle();

      if (response != null && response['access_token'] != null) {
        final key = response['access_token'].toString().trim();
        if (key.isNotEmpty) {
          debugPrint('[GeminiService] Gemini key found: true');
          return key;
        }
      }
      debugPrint('[GeminiService] Gemini key found: false');
    } catch (e) {
      debugPrint('[GeminiService] Could not fetch Gemini key from DB: $e');
    }

    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      debugPrint('[GeminiService] Gemini key found (from env): true');
      return envKey.trim();
    }

    debugPrint('[GeminiService] Gemini key found: false');
    return '';
  }

  /// Detects MIME type from raw audio header bytes
  static String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 4) {
      // RIFF header -> audio/wav
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
        return 'audio/wav';
      }
      // EBML header (0x1A45DFA3) -> audio/webm
      if (bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3) {
        return 'audio/webm';
      }
      // OggS header -> audio/ogg
      if (bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53) {
        return 'audio/ogg';
      }
      // ID3 or 0xFF 0xFB -> audio/mp3
      if ((bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) ||
          (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0)) {
        return 'audio/mp3';
      }
    }
    return 'audio/webm';
  }

  /// Transcribe raw recorded microphone audio using Google Gemini AI
  static Future<Map<String, dynamic>> transcribeAudio({
    required Uint8List audioBytes,
    String? language,
    String? customPrompt,
  }) async {
    if (audioBytes.isEmpty) {
      return {
        'success': false,
        'error': 'No speech detected. Please speak again.',
      };
    }

    final apiKey = await _getGeminiKey();
    if (apiKey.isEmpty) {
      return {
        'success': false,
        'error': 'Gemini AI authentication failed. Please try again.',
      };
    }

    final mimeType = _detectMimeType(audioBytes);
    final base64Audio = base64Encode(audioBytes);

    final langInstruction = (language == 'te_IN' || language == 'te')
        ? 'The expected language is Telugu. Output exact Telugu Unicode characters without translation.'
        : (language == 'en_IN' || language == 'en')
            ? 'The expected language is English. Output exact English characters without translation.'
            : 'Detect language automatically (Telugu, English, or mixed). Output exact spoken words without translation.';

    final promptText = customPrompt ??
        '''You are a speech-to-text transcription engine.

Listen ONLY to the supplied audio.
$langInstruction

Return ONLY the exact words actually spoken by the human.

Do not answer the speaker.
Do not summarize.
Do not explain.
Do not rewrite.
Do not correct grammar.
Do not infer missing words.
Do not add words.
Do not remove spoken words.
Do not translate.

If Telugu is spoken, preserve the exact Telugu words in Telugu Unicode.
If English is spoken, preserve the exact English words.
If mixed Telugu-English is spoken, preserve the mixed language exactly as spoken.
If the audio contains no understandable human speech, return an empty result.

Output ONLY the transcription text.''';

    for (final model in _geminiModels) {
      try {
        debugPrint('[GeminiService] Trying model: $model');
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final payload = {
          'contents': [
            {
              'parts': [
                {
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Audio,
                  }
                },
                {
                  'text': promptText,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.0,
            'topP': 1.0,
          }
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 18));

        debugPrint('[GeminiService] HTTP status: ${response.statusCode}');

        if (response.statusCode == 200) {
          debugPrint('[GeminiService] Transcription response received');
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final first = candidates.first;
            final content = first['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              String text = (parts.first['text'] ?? '').toString().trim();
              
              // Clean prefix labels if any
              text = text.replaceAll(RegExp(r'^(Transcript|Transcription|Spoken Text):\s*', caseSensitive: false), '').trim();
              
              final lower = text.toLowerCase();
              final isAiChatbotResponse = lower.startsWith('sure,') ||
                  lower.startsWith('here is') ||
                  lower.startsWith('the user said') ||
                  lower.startsWith('the speaker') ||
                  lower.startsWith('as an ai') ||
                  text == 'You got a light?' ||
                  text.contains('issue with the water purifier') ||
                  lower.contains('subtitles by') ||
                  lower.contains('thanks for watching');

              if (isAiChatbotResponse) {
                debugPrint('[GeminiService] Generic AI hallucination detected and filtered.');
                return {
                  'success': false,
                  'error': 'No speech detected. Please speak into the mic and try again.',
                };
              }

              if (text.isNotEmpty) {
                debugPrint('[GeminiService] Transcript length: ${text.length}');
                return {
                  'success': true,
                  'text': text,
                  'model': model,
                };
              }
            }
          }
          return {
            'success': false,
            'error': 'No speech detected. Please try again.',
          };
        } else if (response.statusCode == 429) {
          debugPrint('[GeminiService] Model $model rate limited (429), trying next...');
          continue;
        } else if (response.statusCode == 404) {
          debugPrint('[GeminiService] Model $model endpoint 404, trying next...');
          continue;
        } else {
          debugPrint('[GeminiService] Model $model failed with status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('[GeminiService] Exception with model $model: $e');
      }
    }

    return {
      'success': false,
      'error': 'Gemini AI is temporarily unavailable. Please try again later.',
    };
  }
}
