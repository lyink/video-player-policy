import 'package:flutter/material.dart';

class VideoControls extends StatelessWidget {
  final bool isPlaying;
  final double currentPosition;
  final double duration;
  final double playbackSpeed;
  final String mediaName;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeedChange;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool isLooping;
  final bool isShuffling;
  final VoidCallback onToggleLoop;
  final VoidCallback onToggleShuffle;
  final VoidCallback? onShare;

  const VideoControls({
    super.key,
    required this.isPlaying,
    required this.currentPosition,
    required this.duration,
    required this.playbackSpeed,
    required this.mediaName,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeedChange,
    required this.onBack,
    this.onNext,
    this.onPrevious,
    required this.isLooping,
    required this.isShuffling,
    required this.onToggleLoop,
    required this.onToggleShuffle,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _getDisplayName(mediaName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Loop button
                  IconButton(
                    onPressed: onToggleLoop,
                    icon: Icon(
                      Icons.repeat,
                      color: isLooping ? Colors.amber : Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                  // Shuffle button
                  IconButton(
                    onPressed: onToggleShuffle,
                    icon: Icon(
                      Icons.shuffle,
                      color: isShuffling ? Colors.amber : Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                  // Share button
                  if (onShare != null)
                    IconButton(
                      onPressed: onShare,
                      icon: Icon(
                        Icons.share,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                      tooltip: 'Share video',
                    ),
                  // Speed button
                  IconButton(
                    onPressed: () => _showSpeedDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${playbackSpeed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom controls
            Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(Duration(milliseconds: currentPosition.toInt())),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbColor: Colors.white,
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            value: duration > 0 ? currentPosition.clamp(0.0, duration) : 0.0,
                            min: 0.0,
                            max: duration,
                            onChanged: onSeek,
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(Duration(milliseconds: duration.toInt())),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Play controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: onPrevious,
                      icon: Icon(
                        Icons.skip_previous,
                        color: onPrevious != null ? Colors.white : Colors.white54,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _seekRelative(-10000),
                      icon: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: onPlayPause,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _seekRelative(10000),
                      icon: const Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: onNext,
                      icon: Icon(
                        Icons.skip_next,
                        color: onNext != null ? Colors.white : Colors.white54,
                        size: 36,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _seekRelative(int milliseconds) {
    final newPosition = (currentPosition + milliseconds).clamp(0.0, duration);
    onSeek(newPosition);
  }

  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final speed in [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0])
              ListTile(
                title: Text('${speed}x'),
                leading: Radio<double>(
                  value: speed,
                  groupValue: playbackSpeed,
                  onChanged: (value) {
                    if (value != null) {
                      onSpeedChange(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  onSpeedChange(speed);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getDisplayName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      parts.removeLast();
    }
    return parts.join('.');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}