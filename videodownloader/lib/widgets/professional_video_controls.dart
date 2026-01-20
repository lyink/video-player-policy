import 'dart:ui';
import 'package:flutter/material.dart';

class ProfessionalVideoControls extends StatelessWidget {
  final bool isPlaying;
  final double currentPosition;
  final double duration;
  final double playbackSpeed;
  final String mediaName;
  final VoidCallback onPlayPause;
  final Function(double) onSeek;
  final Function(double) onSpeedChange;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool isLooping;
  final bool isShuffling;
  final VoidCallback onToggleLoop;
  final VoidCallback onToggleShuffle;
  final VoidCallback onShare;
  final VoidCallback? onFullscreen;

  const ProfessionalVideoControls({
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
    required this.onShare,
    this.onFullscreen,
  });

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

  @override
  Widget build(BuildContext context) {
    final progress = duration > 0 ? currentPosition / duration : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha((0.7 * 255).round()),
            Colors.black.withAlpha((0.3 * 255).round()),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withAlpha((0.3 * 255).round()),
            Colors.black.withAlpha((0.8 * 255).round()),
          ],
          stops: const [0.0, 0.15, 0.25, 0.75, 0.85, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopBar(context),
          _buildCenterControls(context),
          _buildBottomBar(context, progress),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((0.3 * 255).round()),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withAlpha((0.1 * 255).round()),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    iconSize: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mediaName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Playing video',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.8 * 255).round()),
                          fontSize: 12,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTopButton(
                  icon: Icons.share_rounded,
                  onPressed: onShare,
                ),
                const SizedBox(width: 8),
                _buildTopButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.1 * 255).round()),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: 22,
      ),
    );
  }

  Widget _buildCenterControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onPrevious != null)
          _buildCenterButton(
            icon: Icons.skip_previous_rounded,
            onPressed: onPrevious!,
            size: 60,
            iconSize: 36,
          ),
        const SizedBox(width: 24),
        _buildPlayPauseButton(),
        const SizedBox(width: 24),
        if (onNext != null)
          _buildCenterButton(
            icon: Icons.skip_next_rounded,
            onPressed: onNext!,
            size: 60,
            iconSize: 36,
          ),
      ],
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha((0.2 * 255).round()),
        border: Border.all(
          color: Colors.white.withAlpha((0.4 * 255).round()),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPlayPause,
              child: Center(
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 60,
    double iconSize = 32,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha((0.15 * 255).round()),
        border: Border.all(
          color: Colors.white.withAlpha((0.3 * 255).round()),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, double progress) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((0.4 * 255).round()),
            border: Border(
              top: BorderSide(
                color: Colors.white.withAlpha((0.1 * 255).round()),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withAlpha((0.3 * 255).round()),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withAlpha((0.2 * 255).round()),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      onSeek(value * duration);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Time and controls
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.4 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_formatDuration(Duration(milliseconds: currentPosition.toInt()))} / ${_formatDuration(Duration(milliseconds: duration.toInt()))}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildBottomButton(
                      icon: isShuffling ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                      onPressed: onToggleShuffle,
                      isActive: isShuffling,
                    ),
                    const SizedBox(width: 8),
                    _buildBottomButton(
                      icon: isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                      onPressed: onToggleLoop,
                      isActive: isLooping,
                    ),
                    const SizedBox(width: 8),
                    _buildBottomButton(
                      icon: Icons.speed_rounded,
                      label: '${playbackSpeed}x',
                      onPressed: () => _showSpeedMenu(context),
                    ),
                    if (onFullscreen != null) ...[
                      const SizedBox(width: 8),
                      _buildBottomButton(
                        icon: Icons.fullscreen_rounded,
                        onPressed: onFullscreen!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? label,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withAlpha((0.2 * 255).round())
            : Colors.white.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.white.withAlpha((0.4 * 255).round())
              : Colors.white.withAlpha((0.2 * 255).round()),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeedMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.8 * 255).round()),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.3 * 255).round()),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Playback Speed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
                      final isSelected = (speed - playbackSpeed).abs() < 0.01;
                      return InkWell(
                        onTap: () {
                          onSpeedChange(speed);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withAlpha((0.3 * 255).round())
                                : Colors.white.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withAlpha((0.2 * 255).round()),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.8 * 255).round()),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.3 * 255).round()),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildOptionItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Video Info',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.closed_caption_rounded,
                    title: 'Subtitles',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.settings_rounded,
                    title: 'Quality',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withAlpha((0.5 * 255).round()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
