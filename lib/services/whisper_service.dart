import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'gemini_service.dart';

class WhisperService {
  // ---------------------------------------------------------------------------
  // Endpoint priority order:
  //   1. Google Gemini AI      → Primary high-accuracy multimodal STT (no hallucinations)
  //   2. Groq Cloud Whisper    → Fast cloud fallback (whisper-large-v3)
  //   3. Self-hosted server    → local faster-whisper server
  // ---------------------------------------------------------------------------

  /// Groq API key for cloud Whisper fallback.
  static String _groqKey = '';

  /// Call this from main.dart after dotenv is loaded:
  ///   WhisperService.setApiKey(dotenv.env['GROQ_API_KEY'] ?? '');
  static void setApiKey(String key) {
    final trimmed = key.trim();
    if (trimmed.startsWith('gsk_')) {
      _groqKey = trimmed;
      debugPrint('[WhisperService] Groq API key set — cloud fallback enabled (Groq Whisper).');
    } else if (trimmed.startsWith('sk-')) {
      _groqKey = trimmed;
      debugPrint('[WhisperService] OpenAI API key set — cloud fallback enabled.');
    } else if (trimmed.isNotEmpty) {
      debugPrint('[WhisperService] Unknown API key format.');
    }
  }

  // ---------------------------------------------------------------------------
  // Known Whisper silence & audio noise hallucinations (English & Telugu)
  // When no one speaks into the mic, Whisper AI generates fake default text.
  // This set acts as a strict filter to reject these silent hallucinations.
  // ---------------------------------------------------------------------------
  static final Set<String> _hallucinationBlacklist = {
    // English silence hallucinations
    'you',
    'you.',
    'you!',
    'you?',
    'thank you',
    'thank you.',
    'thank you!',
    'thank you very much',
    'thank you for watching',
    'thank you for watching!',
    'thanks for watching',
    'subtitles by',
    'subtitles by amara.org',
    'amara.org',
    'mb',
    'mbc',
    'bye',
    'bye.',
    'so',
    'so...',
    'yeah',
    'yeah.',
    'hello',
    'hello.',
    'silence',
    'listening...',

    // Telugu silence hallucinations
    'మీడ్డింది',
    'మీడ్డింది మీడ్డింది',
    'మీడ్డింది మీడ్డింది మీడ్డింది',
    'మీడియా',
    'సబ్‌టైటిల్స్',
    'ధన్యవాదాలు',
    'తెలుగు',
    'మరింత చదవండి',
    'చూసినందుకు ధన్యవాదాలు',
    'సబ్‌స్క్రైబ్ చేయండి',
    'సబ్‌స్క్రైబ్',
  };

  // ---------------------------------------------------------------------------
  // Self-hosted endpoints (faster-whisper, no cost, runs on VPS / localhost)
  // ---------------------------------------------------------------------------
  static List<String> get _selfHostedEndpoints {
    final list = <String>[];

    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocalHost = host == 'localhost' || host == '127.0.0.1' || host.isEmpty;
      if (!isLocalHost) {
        list.add('https://$host/api/transcribe');
        list.add('https://$host:8000/api/transcribe');
      }
    }

    list.add('http://127.0.0.1:8000/api/transcribe');
    list.add('http://localhost:8000/api/transcribe');
    list.add('https://smartgov.quantexintelsystems.com/api/transcribe');

    return list.toSet().toList();
  }

  // ---------------------------------------------------------------------------
  // Sanitize Whisper output — strip hallucinated text & silent repetitions
  // ---------------------------------------------------------------------------
  static String sanitizeTranscript(String rawText) {
    if (rawText.isEmpty) return '';

    String text = rawText.trim();
    text = text.replaceAll(RegExp(r'[\u0000-\u001F\u7F]'), '').trim();
    if (text.isEmpty) return '';

    // ── 1. Remove 4+ consecutive identical characters (e.g. ొొొొొ) ──────────
    text = text.replaceAll(RegExp(r'(.)\1{3,}'), '').trim();

    // Normalized lowercase string without special punctuation for blacklist matching
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0C00-\u0C7F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // ── 2. Check Blacklist of Silence Hallucinations ─────────────────────────
    if (_hallucinationBlacklist.contains(normalized)) {
      debugPrint('[WhisperService] Rejected silence hallucination blacklist match: "$text"');
      return '';
    }

    // Check prefix blacklists
    if (normalized.startsWith('subtitles by') ||
        normalized.startsWith('thanks for watching') ||
        normalized.startsWith('thank you for watching') ||
        normalized.startsWith('amara.org') ||
        normalized.startsWith('మీడ్డింది')) {
      debugPrint('[WhisperService] Rejected prefix match hallucination: "$text"');
      return '';
    }

    // ── 3. Character density check ───────────────────────────────────────────
    if (text.length > 8) {
      final charCounts = <String, int>{};
      for (int i = 0; i < text.length; i++) {
        final char = text[i];
        if (char != ' ') charCounts[char] = (charCounts[char] ?? 0) + 1;
      }
      for (final entry in charCounts.entries) {
        if (entry.value / text.length > 0.30) {
          text = text.replaceAll(entry.key, '').trim();
        }
      }
    }

    // ── 4. Detect repetitive word/phrase hallucinations ───────────────────────
    final words = text.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final normalizedWords = words
          .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^\w\u0C00-\u0C7F]'), ''))
          .where((w) => w.isNotEmpty)
          .toList();
      if (normalizedWords.isNotEmpty) {
        final uniqueWords = normalizedWords.toSet();
        if (uniqueWords.length == 1) {
          debugPrint('[WhisperService] Rejected single word repeated in phrase: "$text"');
          return '';
        }
        if (words.length >= 3 && (uniqueWords.length / words.length) <= 0.40) {
          debugPrint('[WhisperService] Rejected repetitive word pattern (${uniqueWords.length}/${words.length}): "$text"');
          return '';
        }
      }
    } else if (words.length == 1) {
      final single = words.first.toLowerCase().replaceAll(RegExp(r'[^\w\u0C00-\u0C7F]'), '');
      if (_hallucinationBlacklist.contains(single)) {
        debugPrint('[WhisperService] Rejected single hallucinated word: "$text"');
        return '';
      }
    }

    // ── 5. Collapse multiple spaces ───────────────────────────────────────────
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  // ---------------------------------------------------------------------------
  // Public: transcribe audio bytes
  // ---------------------------------------------------------------------------

  /// Transcribe [audioBytes] (WebM/WAV/etc.) to text.
  ///
  /// [language] — 'te', 'en', or null/'auto' for auto-detect.
  static Future<Map<String, dynamic>> transcribeAudio({
    required Uint8List audioBytes,
    String? language,
  }) async {
    final langCode = _normaliseLang(language);
    final mode = _modeName(langCode);

    print('================================================================');
    print('[VoiceSTT] 🎙️ RECORDING CAPTURED - STT TRANSCRIPTION INITIATED');
    print('[VoiceSTT] 📦 Audio bytes size: ${audioBytes.length} bytes');
    print('[VoiceSTT] 🌐 Language Mode: $langCode ($mode)');
    print('================================================================');

    if (audioBytes.isEmpty || audioBytes.length < 800) {
      print('[VoiceSTT] ⚠️ Audio data too small or empty (${audioBytes.length} bytes)');
      print('================================================================');
      return {'success': false, 'error': 'No speech detected. Please speak into the mic and try again.'};
    }

    // ── STAGE 1: Try Google Gemini AI first (Multimodal speech recognition) ──
    try {
      final geminiResult = await GeminiService.transcribeAudio(
        audioBytes: audioBytes,
        language: langCode == 'auto' ? null : (langCode == 'te' ? 'te_IN' : 'en_IN'),
      );

      if (geminiResult['success'] == true) {
        final text = sanitizeTranscript((geminiResult['text'] ?? '').toString());
        if (text.isNotEmpty) {
          print('================================================================');
          print('[VoiceSTT] ✅ SPEECH TRANSCRIBED SUCCESSFULLY (Google Gemini AI)');
          print('[VoiceSTT] 🗣️ Transcribed Text: "$text"');
          print('[VoiceSTT] 🌐 Language: $langCode ($mode)');
          print('================================================================');

          return {
            'success': true,
            'text': text,
            'language': langCode,
            'confidence': 0.98,
            'source': 'gemini_ai',
          };
        }
      }
    } catch (e) {
      debugPrint('[WhisperService] Gemini AI STT attempt skipped/failed: $e');
    }

    // ── STAGE 2: Try Groq Whisper & Self-Hosted in parallel ──────────────────
    if (_groqKey.isNotEmpty) {
      final completer = Completer<Map<String, dynamic>>();
      int pending = 2;
      Map<String, dynamic>? lastFailure;

      void onResult(Map<String, dynamic>? result) {
        if (result != null && result['success'] == true && !completer.isCompleted) {
          completer.complete(result);
          return;
        }
        if (result != null) lastFailure = result;
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(lastFailure ?? {
            'success': false,
            'error': 'No speech detected. Please speak clearly into the mic.',
          });
        }
      }

      _trySelfHosted(audioBytes, langCode).then(onResult).catchError((_) => onResult(null));
      _transcribeViaGroq(audioBytes, langCode).then(onResult).catchError((_) => onResult(null));

      final result = await completer.future;
      if (result['success'] == true) {
        final text = sanitizeTranscript((result['text'] ?? '').toString());
        if (text.isNotEmpty) {
          print('================================================================');
          print('[VoiceSTT] ✅ SPEECH TRANSCRIBED SUCCESSFULLY (${result['source'] ?? "Whisper"})');
          print('[VoiceSTT] 🗣️ Transcribed Text: "$text"');
          print('[VoiceSTT] 🌐 Language: ${result['language'] ?? langCode}');
          print('================================================================');
          return {
            'success': true,
            'text': text,
            'language': result['language'] ?? langCode,
            'confidence': result['confidence'] ?? 0.95,
            'source': result['source'] ?? 'whisper',
          };
        }
      }
    } else {
      final result = await _trySelfHosted(audioBytes, langCode);
      if (result != null && result['success'] == true) {
        final text = sanitizeTranscript((result['text'] ?? '').toString());
        if (text.isNotEmpty) {
          print('================================================================');
          print('[VoiceSTT] ✅ SPEECH TRANSCRIBED SUCCESSFULLY (Self-Hosted Whisper)');
          print('[VoiceSTT] 🗣️ Transcribed Text: "$text"');
          print('[VoiceSTT] 🌐 Language: ${result['language'] ?? langCode}');
          print('================================================================');
          return {
            'success': true,
            'text': text,
            'language': result['language'] ?? langCode,
            'confidence': result['confidence'] ?? 0.90,
            'source': 'self_hosted',
          };
        }
      }
    }

    print('================================================================');
    print('[VoiceSTT] ⚠️ NO SPEECH DETECTED (Silence / Audio Noise / Hallucination Filtered)');
    print('[VoiceSTT] ❌ Result: No speech recognized. Please speak into the mic.');
    print('================================================================');

    return {
      'success': false,
      'error': 'No speech detected. Please tap mic and speak clearly.',
    };
  }

  // ---------------------------------------------------------------------------
  // Stage 2 — self-hosted server loop
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> _trySelfHosted(
    Uint8List audioBytes,
    String langCode,
  ) async {
    String lastError = '';

    for (final endpoint in _selfHostedEndpoints) {
      debugPrint('[WhisperService] Trying: $endpoint');
      try {
        final request = http.MultipartRequest('POST', Uri.parse(endpoint));
        request.headers['Accept'] = 'application/json';
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'recording.webm',
        ));
        request.fields['language'] = langCode;

        final streamed = await request.send().timeout(const Duration(seconds: 3));
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 200) {
          Map<String, dynamic> data = {};
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map) data = Map<String, dynamic>.from(decoded);
          } catch (e) {
            debugPrint('[WhisperService] JSON parse error: $e');
          }

          if (data['success'] == true) {
            final text = sanitizeTranscript((data['text'] ?? '').toString().trim());
            if (text.isNotEmpty) {
              return _buildSuccess(data, text, langCode);
            }
          }

          return {
            'success': false,
            'error': data['error'] ?? 'Speech could not be recognized. Please try again.',
          };
        } else if (response.statusCode == 413) {
          return {'success': false, 'error': 'Audio file is too large.'};
        } else {
          lastError = 'Server error ${response.statusCode} from $endpoint.';
        }
      } on TimeoutException {
        lastError = 'Timeout connecting to $endpoint.';
      } catch (e) {
        final str = e.toString();
        if (kIsWeb && str.contains('Failed to fetch')) {
          lastError = 'CORS/network error on $endpoint.';
        } else {
          lastError = 'Connection failed ($endpoint): $e';
        }
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Stage 3 — Groq Whisper cloud API
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> _transcribeViaGroq(
    Uint8List audioBytes,
    String langCode,
  ) async {
    const groqUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
    const modelName = 'whisper-large-v3';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(groqUrl));
      request.headers['Authorization'] = 'Bearer $_groqKey';
      request.headers['Accept'] = 'application/json';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: 'recording.webm',
      ));

      request.fields['model'] = modelName;
      if (langCode != 'auto') {
        request.fields['language'] = langCode;
      }
      request.fields['prompt'] = '';
      request.fields['response_format'] = 'verbose_json';

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = {};
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) data = Map<String, dynamic>.from(decoded);
        } catch (e) {
          debugPrint('[WhisperService] Groq JSON parse error: $e');
        }

        final rawText = (data['text'] ?? '').toString().trim();

        // ── no_speech_prob guard ─────────────────────────────────────────────
        final segments = data['segments'];
        if (segments is List && segments.isNotEmpty) {
          final avgNoSpeech = segments
              .map((s) => (s['no_speech_prob'] ?? 0.0) as num)
              .reduce((a, b) => a + b) / segments.length;
          debugPrint('[WhisperService] Groq no_speech_prob avg: ${avgNoSpeech.toStringAsFixed(2)}');
          if (avgNoSpeech > 0.45) {
            debugPrint('[WhisperService] Rejected: no speech detected (no_speech_prob=${avgNoSpeech.toStringAsFixed(2)})');
            return {'success': false, 'error': 'No speech detected. Please tap mic and speak clearly.'};
          }
        }

        final text = sanitizeTranscript(rawText);
        final detectedLang = (data['language'] ?? langCode).toString();

        if (text.isNotEmpty) {
          return {
            'success': true,
            'text': text,
            'language': detectedLang,
            'confidence': 0.95,
            'contains_telugu': _containsTelugu(text),
            'contains_devanagari': _containsDevanagari(text),
            'telugu_ratio': 0.0,
            'devanagari_ratio': 0.0,
            'source': 'groq_cloud',
          };
        }

        return {'success': false, 'error': 'No transcription returned. Please speak clearly and try again.'};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Voice service authentication failed.'};
      } else if (response.statusCode == 429) {
        return {'success': false, 'error': 'Voice service is busy. Please wait a moment and try again.'};
      } else if (response.statusCode == 413) {
        return {'success': false, 'error': 'Audio clip is too long.'};
      } else {
        return {'success': false, 'error': 'Voice service error (${response.statusCode}). Please try again.'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Voice service timed out. Please check your connection.'};
    } catch (e) {
      return {'success': false, 'error': 'Voice service unavailable. Please try again.'};
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _normaliseLang(String? language) {
    if (language == null) return 'auto';
    final l = language.toLowerCase().trim();
    if (l == 'te' || l == 'te_in' || l == 'te-in' || l == 'telugu') return 'te';
    if (l == 'en' || l == 'en_in' || l == 'en-in' || l == 'english') return 'en';
    return 'auto';
  }

  static String _modeName(String langCode) {
    if (langCode == 'te') return 'Telugu';
    if (langCode == 'en') return 'English';
    return 'Auto Detect';
  }

  static Map<String, dynamic> _buildSuccess(
    Map<String, dynamic> data,
    String text,
    String fallbackLang,
  ) {
    return {
      'success': true,
      'text': text,
      'language': data['language'] ?? fallbackLang,
      'confidence': data['confidence'] ?? 0.0,
      'contains_telugu': data['contains_telugu'] ?? false,
      'contains_devanagari': data['contains_devanagari'] ?? false,
      'telugu_ratio': data['telugu_ratio'] ?? 0.0,
      'devanagari_ratio': data['devanagari_ratio'] ?? 0.0,
      'source': 'self_hosted',
    };
  }

  static bool _containsTelugu(String text) =>
      text.runes.any((r) => r >= 0x0C00 && r <= 0x0C7F);

  static bool _containsDevanagari(String text) =>
      text.runes.any((r) => r >= 0x0900 && r <= 0x097F);
}


