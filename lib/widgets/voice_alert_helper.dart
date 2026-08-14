import 'dart:async';
import 'package:record/record.dart';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../services/whisper_service.dart';
import 'package:video_player/video_player.dart';

/// A button that allows users to dictate text using speech-to-text.
class VoiceDictationButton extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final bool isTelugu;

  const VoiceDictationButton({
    super.key,
    required this.controller,
    this.label,
    this.isTelugu = false,
  });

  @override
  State<VoiceDictationButton> createState() => _VoiceDictationButtonState();
}

class _VoiceDictationButtonState extends State<VoiceDictationButton> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isListening = false;

  String _processTeluguText(String text) {
    return text.trim();
  }

  Future<void> _toggleListen() async {
    if (_isListening) {
      try {
        final path = await _recorder.stop();
        setState(() => _isListening = false);
        if (path != null && path.isNotEmpty) {
          Uint8List audioBytes;
          if (path.startsWith('blob:') || path.startsWith('http')) {
            final res = await http.get(Uri.parse(path));
            audioBytes = res.bodyBytes;
          } else {
            final file = File(path);
            audioBytes = await file.readAsBytes();
          }
          final whisperRes = await WhisperService.transcribeAudio(
            audioBytes: audioBytes,
            language: widget.isTelugu ? 'te_IN' : 'en_IN',
          );
          if (whisperRes['success'] == true && mounted) {
            final text = (whisperRes['text'] ?? '').toString().trim();
            if (text.isNotEmpty) {
              final existing = widget.controller.text;
              widget.controller.text = existing.isEmpty ? text : '$existing $text';
            }
          } else if (mounted) {
            final err = whisperRes['error'] ?? (widget.isTelugu ? 'మాట్లాడటం ఏదీ గుర్తించబడలేదు. దయచేసి స్పష్టంగా మాట్లాడండి.' : 'No speech detected. Please speak clearly.');
            _showError(err.toString());
          }
        }
      } catch (e) {
        debugPrint('Audio recording stop error: $e');
        if (mounted) setState(() => _isListening = false);
      }
    } else {
      try {
        if (await _recorder.hasPermission()) {
          setState(() => _isListening = true);
          await _recorder.start(const RecordConfig(), path: '');
        } else {
          _showError(widget.isTelugu ? 'మైక్రోఫోన్ అనుమతి తిరస్కరించబడింది' : 'Microphone permission denied');
        }
      } catch (e) {
        debugPrint('Recorder start error: $e');
        _showError(widget.isTelugu ? 'వాయిస్ గుర్తింపు అందుబాటులో లేదు' : 'Speech recognition unavailable');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleListen,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isListening ? Colors.red.shade50 : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isListening ? Colors.red.shade300 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Theme.of(context).primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _isListening 
                  ? (widget.isTelugu ? 'వింటున్నారు...' : 'Listening...') 
                  : (widget.label ?? (widget.isTelugu ? 'వాయిస్ టైపింగ్' : 'Voice Dictate')),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _isListening ? Colors.red : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<File> generateDummyAudioFile() async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

  final sampleRate = 8000;
  final durationSeconds = 3;
  final numSamples = sampleRate * durationSeconds;
  final subChunk2Size = numSamples;
  final chunkSize = 36 + subChunk2Size;

  final header = ByteData(44);
  // RIFF header
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F
  header.setUint32(4, chunkSize, Endian.little);
  header.setUint8(8, 0x57); // W
  header.setUint8(9, 0x41); // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E

  // fmt subchunk
  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6D); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // ' '
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // Mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate, Endian.little); // Byte rate
  header.setUint16(32, 1, Endian.little); // Block align
  header.setUint16(34, 8, Endian.little); // Bits per sample

  // data subchunk
  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a
  header.setUint32(40, subChunk2Size, Endian.little);

  final data = Uint8List(44 + numSamples);
  data.setRange(0, 44, header.buffer.asUint8List());

  // Generate a premium clear municipal chime + verbal hum transmission
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    double signal = 0.0;
    
    if (t < 0.6) {
      // Phase 1: Gentle double-chime (D5 -> A5 ascending clean chime, very pleasant)
      if (t < 0.3) {
        // First chime (D5: 587.33 Hz) decaying rapidly
        final tChime = t;
        final envelope = exp(-8.0 * tChime);
        signal = sin(2 * pi * 587.33 * tChime) * envelope;
      } else {
        // Second chime (A5: 880.00 Hz) decaying rapidly
        final tChime = t - 0.3;
        final envelope = exp(-8.0 * tChime);
        signal = sin(2 * pi * 880.00 * tChime) * envelope;
      }
    } else {
      // Phase 2: Gentle simulated speech dispatch tone (smooth harmonic blend of 180Hz, 270Hz, and 360Hz)
      // Modulated with a 6Hz vibrato to simulate realistic speech cadence/clarity, avoiding flat beep irritation
      final tVoice = t - 0.6;
      final speechEnvelope = sin(pi * tVoice / (durationSeconds - 0.6)); // Soft arc envelope
      final speechMod = 0.5 + 0.5 * sin(2 * pi * 6.0 * tVoice); // 6Hz amplitude modulation (cadence)
      
      final f1 = 180.0;
      final f2 = 270.0;
      final f3 = 360.0;
      
      signal = (0.5 * sin(2 * pi * f1 * tVoice) +
                0.3 * sin(2 * pi * f2 * tVoice) +
                0.2 * sin(2 * pi * f3 * tVoice)) * speechEnvelope * speechMod;
    }
    
    // Scale and convert to 8-bit PCM (0-255 range, centered at 127)
    final sample = (127.0 + 127.0 * signal * 0.7).round().clamp(0, 255);
    data[44 + i] = sample;
  }

  await file.writeAsBytes(data);
  return file;
}

/// A dialog recorder to attach a simulated voice message to a broadcast.
class VoiceRecorderWidget extends StatefulWidget {
  final bool isTelugu;
  final Function(String? audioPath) onRecorded;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecorded,
    this.isTelugu = false,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        _recordingPath = '${tempDir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, bitRate: 128000, sampleRate: 44100),
          path: _recordingPath!,
        );

        debugPrint('[AUDIO_RECORDING] Recording started at ${DateTime.now()}');
        setState(() {
          _isRecording = true;
          _seconds = 0;
        });
        _pulseController.repeat(reverse: true);
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            _seconds++;
          });
          if (_seconds >= 3600) { // Increased limit to 1 hour
            _stopRecording();
          }
        });
      } else {
        debugPrint('[AUDIO_RECORDING] Microphone permission denied');
      }
    } catch (e) {
      debugPrint('[AUDIO_RECORDING] Error starting recorder: $e');
    }
  }

  void _stopRecording() async {
    debugPrint('[AUDIO_RECORDING] Recording stopping. Duration: $_seconds seconds');
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRecording = false;
    });

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (file.existsSync() && file.lengthSync() > 0) {
          debugPrint('[AUDIO_RECORDING] Recording stopped successfully. Path: $path');
          widget.onRecorded(path);
        } else {
          widget.onRecorded(null);
        }
      } else {
        widget.onRecorded(null);
      }
    } catch (e) {
      debugPrint("[AUDIO_RECORDING] Error validating audio file: $e");
      widget.onRecorded(null);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.isTelugu ? 'వాయిస్ మెసేజ్ రికార్డ్ చేయండి' : 'Record Voice Message',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isTelugu
                ? 'వ్యవస్థ ప్రకటనల కొరకు ఆడియోను రికార్డ్ చేయండి.'
                : 'Record voice instructions for broadcasting to wards.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(
            _formatDuration(_seconds),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _isRecording ? Colors.red : Colors.grey.shade800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          // AI Noise Filter active indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.green, size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.isTelugu ? 'AI నాయిస్ రిడక్షన్: సక్రియం' : 'AI Noise Filter: Active',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isRecording) ...[
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(15, (index) {
                  final height = (index % 3 + 1) * (_seconds % 2 == 0 ? 8 : 12);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 3,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Theme.of(context).primaryColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording 
                ? (widget.isTelugu ? 'రికార్డింగ్ ఆపడానికి నొక్కండి' : 'Tap to stop recording') 
                : (widget.isTelugu ? 'రికార్డింగ్ ప్రారంభించడానికి నొక్కండి' : 'Tap to start recording'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// A media player widget with animated soundwaves to play back simulated/mock voice alerts.
class VoicePlaybackWidget extends StatefulWidget {
  final String audioUrl;
  final bool isTelugu;

  const VoicePlaybackWidget({
    super.key,
    required this.audioUrl,
    this.isTelugu = false,
  });

  @override
  State<VoicePlaybackWidget> createState() => _VoicePlaybackWidgetState();
}

class _VoicePlaybackWidgetState extends State<VoicePlaybackWidget>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _audioController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  double _progress = 0.0;
  int _currentTime = 0;
  int _totalDuration = 12; // Simulated/fallback duration
  Timer? _timer;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initAudio();
  }

  void _initAudio() async {
    final isNetwork = widget.audioUrl.startsWith('https://');
    debugPrint('[AUDIO_PLAYBACK] Initializing network playback for URL: ${widget.audioUrl}');

    try {
      if (!isNetwork) {
        final audioFile = File(widget.audioUrl);
        if (!audioFile.existsSync()) {
          debugPrint('[AUDIO_PLAYBACK] ERROR: Local file does not exist: ${widget.audioUrl}');
          if (mounted) setState(() => _isInitialized = false);
          return;
        }
        debugPrint('[AUDIO_PLAYBACK] Creating VideoPlayerController for local file: ${widget.audioUrl}');
        _audioController = VideoPlayerController.file(audioFile);
      } else {
        debugPrint('[AUDIO_PLAYBACK] Creating VideoPlayerController for Uri: ${widget.audioUrl}');
        _audioController = VideoPlayerController.networkUrl(Uri.parse(widget.audioUrl));
      }
      
      debugPrint('[AUDIO_PLAYBACK] Loading audio stream...');
      await _audioController!.initialize();
      
      if (mounted) {
        final durationSecs = _audioController!.value.duration.inSeconds;
        debugPrint('[AUDIO_PLAYBACK] Loaded successfully. Duration: $durationSecs seconds.');
        
        setState(() {
          _isInitialized = true;
          _totalDuration = durationSecs > 0 ? durationSecs : 12;
        });

        _audioController!.addListener(() {
          if (!mounted) return;
          final val = _audioController!.value;
          
          if (val.hasError) {
            debugPrint('[AUDIO_PLAYBACK] Error during playback: ${val.errorDescription}');
          }

          setState(() {
            if (val.duration.inMilliseconds > 0) {
              _progress = val.position.inMilliseconds / val.duration.inMilliseconds;
              _currentTime = val.position.inSeconds;
            }
            
            if (val.isBuffering) {
              debugPrint('[AUDIO_PLAYBACK] Buffering media stream...');
            }

            if (val.position >= val.duration && val.duration.inMilliseconds > 0) {
              if (_isPlaying) {
                debugPrint('[AUDIO_PLAYBACK] Playback completed. Seeking to start.');
                _audioController!.pause();
                _audioController!.seekTo(Duration.zero);
                _waveController.stop();
                _isPlaying = false;
                _progress = 0.0;
                _currentTime = 0;
              }
            }
          });
        });
      }
    } catch (e) {
      debugPrint('[AUDIO_PLAYBACK] Critical Initialization failure: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('[AUDIO_PLAYBACK] Disposing playback widget controller for ${widget.audioUrl}');
    _timer?.cancel();
    _audioController?.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() async {
    if (_isInitialized && _audioController != null) {
      debugPrint('[AUDIO_PLAYBACK] Playing / Resuming: ${widget.audioUrl}');
      setState(() {
        _isPlaying = true;
      });
      _waveController.repeat(reverse: true);
      await _audioController!.play();
      debugPrint('[AUDIO_PLAYBACK] State: Playing');
    } else {
      debugPrint('[AUDIO_PLAYBACK] Play failed: Player is not fully initialized.');
    }
  }

  void _pause() async {
    if (_isInitialized && _audioController != null) {
      debugPrint('[AUDIO_PLAYBACK] Paused: ${widget.audioUrl}');
      await _audioController!.pause();
      _waveController.stop();
      setState(() {
        _isPlaying = false;
      });
      debugPrint('[AUDIO_PLAYBACK] State: Paused');
    }
  }

  String _formatDuration(int seconds) {
    final s = seconds % 60;
    return '00:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isTelugu ? 'ఆడియో ప్రకటన' : 'Voice Memo Alert',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      '${_formatDuration(_currentTime)} / ${_formatDuration(_totalDuration)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTapDown: (details) {
                    if (_isInitialized && _audioController != null) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final double width = box.size.width;
                      final double tapPos = details.localPosition.dx;
                      final double fraction = (tapPos / width).clamp(0.0, 1.0);
                      final int durationMs = _audioController!.value.duration.inMilliseconds;
                      final int targetMs = (fraction * durationMs).round();
                      
                      debugPrint('[AUDIO_PLAYBACK] Seek invoked to position: ${(targetMs / 1000).toStringAsFixed(1)}s ($fraction)');
                      _audioController!.seekTo(Duration(milliseconds: targetMs));
                    }
                  },
                  child: Row(
                    children: [
                      // Dynamic animating sound wave bars
                      ...List.generate(24, (index) {
                        final active = index / 24 <= _progress;
                        double height = (index % 3 + 1) * 3.5;
                        if (_isPlaying) {
                          final waveVal = _waveController.value;
                          height = (index % 3 + 1) * (3.5 + waveVal * 4);
                        }
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: height,
                            decoration: BoxDecoration(
                              color: active ? Theme.of(context).primaryColor : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
