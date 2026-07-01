import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const VideoPreviewWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
  });

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant VideoPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _hasError = false;
      _initializeController();
    }
  }

  void _initializeController() {
    final rawUrl = widget.videoUrl;
    VideoPlayerController? controller;

    try {
      if (kIsWeb) {
        // On Flutter Web, always use networkUrl.
        // blob: URLs from image_picker work perfectly with the HTML <video> element.
        final uri = Uri.tryParse(rawUrl) ?? Uri.parse('');
        controller = VideoPlayerController.networkUrl(uri);
      } else if (rawUrl.startsWith('local_video:')) {
        final path = rawUrl.replaceFirst('local_video:', '');
        controller = VideoPlayerController.file(File(path));
      } else if (rawUrl.startsWith('local:')) {
        final path = rawUrl.replaceFirst('local:', '');
        controller = VideoPlayerController.file(File(path));
      } else if (rawUrl.startsWith('/') ||
          (rawUrl.contains(':\\') || rawUrl.contains(':/')) &&
              !rawUrl.startsWith('http')) {
        controller = VideoPlayerController.file(File(rawUrl));
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(rawUrl));
      }

      _controller = controller;
      controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            if (widget.autoPlay) {
              _controller?.play();
            }
          });
        }
      }).catchError((e) {
        debugPrint('Video initialization error: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      debugPrint('Video setup error: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
      } else {
        _controller!.play();
        // Hide controls after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _controller!.value.isPlaying) {
            setState(() {
              _showControls = false;
            });
          }
        });
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_camera_back_outlined, color: Colors.white54, size: 40),
              SizedBox(height: 8),
              Text(
                'Unsupported video or format error',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: VideoPlayer(_controller!),
            ),
            
            // Subtle black gradients on top and bottom for control readability
            if (_showControls) ...[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // Center Play/Pause button
              Center(
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

              // Top right mute button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
              ),

              // Bottom control bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Video Progress bar
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF14B8A6),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: _controller!,
                            builder: (context, VideoPlayerValue value, child) {
                              return Text(
                                _formatDuration(value.position),
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              );
                            },
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
