import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:exim_graphics_lms/core/services/screen_security_service.dart';

class DynamicWatermarkVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String studentId;
  final String phoneNumber;
  final String title;

  const DynamicWatermarkVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.studentId,
    required this.phoneNumber,
    required this.title,
  });

  @override
  State<DynamicWatermarkVideoPlayer> createState() =>
      _DynamicWatermarkVideoPlayerState();
}

class _DynamicWatermarkVideoPlayerState
    extends State<DynamicWatermarkVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  // Watermark positioning
  double _watermarkTop = 50.0;
  double _watermarkLeft = 50.0;
  Timer? _watermarkTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    _initVideoPlayer();
    _startWatermarkAnimation();
  }

  /// Prevents screenshots and screen recording on Android
  Future<void> _enableScreenProtection() async {
    await ScreenSecurityService.enableSecure();
  }

  /// Removes screen protection flags when leaving player screen
  Future<void> _disableScreenProtection() async {
    await ScreenSecurityService.disableSecure();
  }

  void _initVideoPlayer() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  /// Moves the watermark text randomly every 4 seconds to deter video capture
  void _startWatermarkAnimation() {
    _watermarkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final Size screenSize = MediaQuery.of(context).size;
      setState(() {
        _watermarkTop = 40 + _random.nextDouble() * (screenSize.height * 0.4);
        _watermarkLeft = 20 + _random.nextDouble() * (screenSize.width * 0.5);
      });
    });
  }

  @override
  void dispose() {
    _watermarkTimer?.cancel();
    _controller.dispose();
    _disableScreenProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watermarkText = '${widget.studentId} • ${widget.phoneNumber}';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: _hasError
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Failed to load secure stream.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                )
              : !_isInitialized
                  ? const CircularProgressIndicator(
                      color: Colors.deepPurpleAccent)
                  : Stack(
                      children: [
                        // Video Player Content
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),

                        // Dynamic Animated Anti-Piracy Watermark Overlay
                        AnimatedPositioned(
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          top: _watermarkTop,
                          left: _watermarkLeft,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.white24, width: 0.8),
                              ),
                              child: Text(
                                watermarkText,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Custom Video Controls Overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller.value.isPlaying
                                          ? _controller.pause()
                                          : _controller.play();
                                    });
                                  },
                                ),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.deepPurpleAccent,
                                      bufferedColor: Colors.white30,
                                      backgroundColor: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
