// lib/features/conversations/presentation/widgets/voice_message_widget.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Voice message player and recorder widget for chat
/// Provides recording, playback, and visualization features
class VoiceMessageWidget extends StatefulWidget {
  final String? audioUrl;
  final Duration? duration;
  final bool isCurrentUser;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;

  const VoiceMessageWidget({
    super.key,
    this.audioUrl,
    this.duration,
    this.isCurrentUser = false,
    this.onPlay,
    this.onPause,
    this.onStop,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  late AnimationController _waveAnimationController;
  late AnimationController _playButtonController;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 280,
      ),
      decoration: BoxDecoration(
        color: widget.isCurrentUser
            ? Theme.of(context).primaryColor
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isCurrentUser
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isCurrentUser
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isCurrentUser
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      size: 20,
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Waveform visualization
          Expanded(
            child: SizedBox(
              height: 32,
              child: _buildWaveform(),
            ),
          ),

          const SizedBox(width: 8),

          // Duration text
          Text(
            _formatDuration(widget.duration ?? Duration.zero),
            style: TextStyle(
              fontSize: 12,
              color: widget.isCurrentUser
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: WaveformPainter(
            animationValue: _waveAnimationController.value,
            isPlaying: _isPlaying,
            currentPosition: _currentPosition,
            totalDuration: widget.duration ?? Duration.zero,
            color: widget.isCurrentUser
                ? Colors.white.withValues(alpha: 0.7)
                : Theme.of(context).primaryColor.withValues(alpha: 0.7),
            activeColor: widget.isCurrentUser
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
          size: const Size(double.infinity, 32),
        );
      },
    );
  }

  void _togglePlayback() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _isLoading = false;
        _isPlaying = !_isPlaying;
      });

      if (_isPlaying) {
        _waveAnimationController.repeat();
        _playButtonController.forward();
        widget.onPlay?.call();
        _simulatePlayback();
      } else {
        _waveAnimationController.stop();
        _playButtonController.reverse();
        widget.onPause?.call();
      }
    });
  }

  void _simulatePlayback() {
    if (!_isPlaying) return;

    final totalSeconds = (widget.duration?.inSeconds ?? 30);
    final increment = Duration(seconds: totalSeconds ~/ 50); // 50 steps

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentPosition += increment;
        if (_currentPosition >= (widget.duration ?? Duration.zero)) {
          _currentPosition = widget.duration ?? Duration.zero;
          _isPlaying = false;
          _waveAnimationController.stop();
          _playButtonController.reverse();
          timer.cancel();
        }
      });
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Voice message recorder widget for capturing audio
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String audioPath, Duration duration)? onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),

          // Recording status
          Text(
            _isRecording ? 'Ses Kaydediliyor...' : 'Dokunup Basılı Tutun',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // Recording duration
          Text(
            _formatDuration(_recordingDuration),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // Waveform visualization
          SizedBox(
            height: 60,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RecordingWaveformPainter(
                    animationValue: _waveController.value,
                    isRecording: _isRecording,
                    color: Theme.of(context).primaryColor,
                  ),
                  size: const Size(double.infinity, 60),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel button
              IconButton(
                onPressed: _isRecording ? null : () => widget.onCancel?.call(),
                icon: const Icon(Icons.close),
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  disabledBackgroundColor: Colors.grey.shade100,
                ),
              ),

              // Record button
              GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                onTapCancel: () => _stopRecording(),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 20 * _pulseController.value,
                                  spreadRadius: 5 * _pulseController.value,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 36,
                      ),
                    );
                  },
                ),
              ),

              // Send button
              IconButton(
                onPressed: _isRecording || _recordingDuration.inSeconds < 1
                    ? null
                    : _sendRecording,
                icon: const Icon(Icons.send),
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  disabledBackgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Instructions
          Text(
            _isRecording
                ? 'Kaydı durdurmak için bırakın'
                : 'Kayıt yapmak için mikrofona basılı tutun',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _startRecording() {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _pulseController.repeat();
    _waveController.repeat();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });

      // Maximum recording time (5 minutes)
      if (_recordingDuration.inMinutes >= 5) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    _recordingTimer?.cancel();
    _pulseController.stop();
    _waveController.stop();
  }

  void _sendRecording() {
    if (_recordingDuration.inSeconds < 1) return;

    // In a real implementation, this would return the actual audio file path
    final fakePath = 'voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
    widget.onRecordingComplete?.call(fakePath, _recordingDuration);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final Color color;
  final Color activeColor;

  WaveformPainter({
    required this.animationValue,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    const barCount = 30;
    final barWidth = size.width / barCount;
    final progress = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final normalizedHeight = (i % 3 + 1) / 3; // Varied heights
      final baseHeight = size.height * 0.3;
      final maxHeight = size.height * 0.9;
      
      double height = baseHeight + (maxHeight - baseHeight) * normalizedHeight;
      
      if (isPlaying) {
        // Add animation effect
        final animationOffset = (animationValue + i * 0.1) % 1.0;
        height *= (0.5 + 0.5 * (1 + math.sin(animationOffset * math.pi * 2)) / 2);
      }

      final isActive = (i / barCount) <= progress;
      final currentPaint = isActive ? activePaint : paint;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height / 2),
          width: barWidth * 0.6,
          height: height,
        ),
        const Radius.circular(1),
      );

      canvas.drawRRect(rect, currentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for recording waveform
class RecordingWaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isRecording;
  final Color color;

  RecordingWaveformPainter({
    required this.animationValue,
    required this.isRecording,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    const barCount = 20;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final animationOffset = (animationValue + i * 0.15) % 1.0;
      final height = size.height * 0.2 + 
          size.height * 0.6 * (1 + math.sin(animationOffset * math.pi * 4)) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height / 2),
          width: barWidth * 0.7,
          height: height,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
