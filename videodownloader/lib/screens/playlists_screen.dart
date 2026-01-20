import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_file.dart';
import '../providers/theme_provider.dart';
import '../services/simple_audio_service.dart';

class ProfessionalAudioPlayer extends StatefulWidget {
  final MediaFile media;
  final List<MediaFile>? playlist;
  final int? currentIndex;

  const ProfessionalAudioPlayer({
    super.key,
    required this.media,
    this.playlist,
    this.currentIndex,
  });

  @override
  State<ProfessionalAudioPlayer> createState() =>
      _ProfessionalAudioPlayerState();
}

class _ProfessionalAudioPlayerState extends State<ProfessionalAudioPlayer>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _playButtonController;
  late AnimationController _albumRotationController;
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _playButtonAnimation;
  late Animation<double> _albumRotationAnimation;
  late Animation<double> _glowAnimation;

  bool _showPlaylist = false;
  bool _isShuffled = false;
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _albumRotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _playButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
    );

    _albumRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _albumRotationController, curve: Curves.linear),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '${hours}:${minutes}:${seconds}';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    _albumRotationController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Consumer<SimpleAudioService>(
      builder: (context, audioService, child) {
        // Update animations based on audio service state
        if (audioService.isPlaying) {
          if (!_playButtonController.isAnimating &&
              _playButtonController.status != AnimationStatus.completed) {
            _playButtonController.forward();
          }
          if (_albumRotationController.status != AnimationStatus.forward) {
            _albumRotationController.repeat();
          }
        } else {
          if (!_playButtonController.isAnimating &&
              _playButtonController.status != AnimationStatus.dismissed) {
            _playButtonController.reverse();
          }
          if (_albumRotationController.isAnimating) {
            _albumRotationController.stop();
          }
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(isDark),
          body: Stack(
            children: [
              // Animated background
              _buildAnimatedBackground(isDark, audioService.isPlaying),

              // Content
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _showPlaylist
                      ? _buildPlaylistView(audioService, isDark)
                      : _buildPlayerView(audioService, isDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ]
                  : [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.05),
                    ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 28,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Add to favorites
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.05),
                      ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 22,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() {
              _showPlaylist = !_showPlaylist;
            });
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: _showPlaylist
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.4),
                        Theme.of(context).primaryColor.withOpacity(0.2),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ]
                          : [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.05),
                            ],
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: _showPlaylist
                    ? Theme.of(context).primaryColor.withOpacity(0.6)
                    : (isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.15)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _showPlaylist
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.queue_music_rounded,
              size: 22,
              color: _showPlaylist
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAnimatedBackground(bool isDark, bool isPlaying) {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _glowAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0a0e27),
                      const Color(0xFF1a1a3e),
                      const Color(0xFF16213e),
                      const Color(0xFF0f1729),
                    ]
                  : [
                      const Color(0xFFf8f9fa),
                      const Color(0xFFffffff),
                      const Color(0xFFf1f3f5),
                      const Color(0xFFe9ecef),
                    ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated particles/orbs
              if (isPlaying) ...[
                for (int i = 0; i < 5; i++)
                  Positioned(
                    left:
                        (i * 100 + _particleController.value * 50) %
                        MediaQuery.of(context).size.width,
                    top:
                        (i * 80 + _particleController.value * 100) %
                        MediaQuery.of(context).size.height,
                    child: Container(
                      width: 100 + (i * 20),
                      height: 100 + (i * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(
                              0.1 * _glowAnimation.value,
                            ),
                            Theme.of(context).primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerView(SimpleAudioService audioService, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAlbumArtSection(audioService.isPlaying, isDark),
            const SizedBox(height: 40),
            _buildSongInfo(audioService, isDark),
            const SizedBox(height: 40),
            _buildProgressSection(audioService, isDark),
            const SizedBox(height: 40),
            _buildMainControls(audioService, isDark),
            const SizedBox(height: 32),
            _buildSecondaryControls(audioService, isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtSection(bool isPlaying, bool isDark) {
    return Hero(
      tag: 'album_art_${widget.media.path}',
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.5 * _glowAnimation.value),
                  blurRadius: 60,
                  offset: const Offset(0, 25),
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(
                    0.3 * _glowAnimation.value,
                  ),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Rotating gradient background
                  AnimatedBuilder(
                    animation: _albumRotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _albumRotationAnimation.value * 2 * 3.14159,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: SweepGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.6),
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.6),
                                Theme.of(context).primaryColor.withOpacity(0.8),
                                Theme.of(context).primaryColor,
                              ],
                              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Glassmorphic overlay with noise texture
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                            Colors.white.withOpacity(isDark ? 0.05 : 0.15),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(isDark ? 0.2 : 0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // Animated music icon with wave effect
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isPlaying
                                  ? 1.0 + (_waveController.value * 0.15)
                                  : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 100,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            );
                          },
                        ),
                        if (isPlaying) ...[
                          const SizedBox(height: 24),
                          _buildWaveformIndicator(),
                        ],
                      ],
                    ),
                  ),

                  // Playing indicator badge
                  if (isPlaying)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveformIndicator() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final delay = index * 0.2;
            final animValue = (_waveController.value + delay) % 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 16 + (animValue * 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSongInfo(SimpleAudioService audioService, bool isDark) {
    final currentMedia = audioService.currentMedia;
    if (currentMedia == null) {
      return Column(
        children: [
          Text(
            'No media loaded',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select an audio file to play',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          currentMedia.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            height: 1.2,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.15),
                Theme.of(context).primaryColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Unknown Artist',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (audioService.playlist.length > 1) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.queue_music_rounded,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  'Track ${audioService.currentIndex + 1} of ${audioService.playlist.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(SimpleAudioService audioService, bool isDark) {
    final position = audioService.position;
    final duration = audioService.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
              : [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress track with gradient
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Custom slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 22,
                  ),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final position = Duration(
                      milliseconds: (value * duration.inMilliseconds).round(),
                    );
                    audioService.seekTo(position);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.2),
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatDuration(position),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatDuration(duration),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls(SimpleAudioService audioService, bool isDark) {
    final isPlaying = audioService.isPlaying;
    final canSkipPrevious = audioService.canSkipPrevious;
    final canSkipNext = audioService.canSkipNext;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        _buildControlButton(
          icon: Icons.skip_previous_rounded,
          onPressed: canSkipPrevious ? audioService.skipPrevious : null,
          size: 64,
          iconSize: 36,
          isDark: isDark,
        ),

        const SizedBox(width: 24),

        // Play/Pause button with advanced styling
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.6 * _glowAnimation.value),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(
                      0.4 * _glowAnimation.value,
                    ),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: audioService.togglePlayPause,
                  borderRadius: BorderRadius.circular(45),
                  child: AnimatedBuilder(
                    animation: _playButtonAnimation,
                    builder: (context, child) {
                      return Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return RotationTransition(
                              turns: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(isPlaying),
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 24),

        // Next button
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: canSkipNext ? audioService.skipNext : null,
          size: 64,
          iconSize: 36,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 60,
    double iconSize = 32,
    required bool isDark,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onPressed != null
              ? (isDark
                    ? [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.03),
                      ])
              : [Colors.transparent, Colors.transparent],
        ),
        border: Border.all(
          color: onPressed != null
              ? (isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15))
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
          width: 1.5,
        ),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            size: iconSize,
            color: onPressed != null
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryControls(SimpleAudioService audioService, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [
                  Colors.black.withOpacity(0.03),
                  Colors.black.withOpacity(0.01),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSecondaryButton(
            icon: Icons.shuffle_rounded,
            onPressed: () {
              setState(() {
                _isShuffled = !_isShuffled;
              });
            },
            isActive: _isShuffled,
            isDark: isDark,
          ),
          _buildSecondaryButton(
            icon: Icons.repeat_rounded,
            onPressed: () {
              setState(() {
                _isRepeating = !_isRepeating;
              });
            },
            isActive: _isRepeating,
            isDark: isDark,
          ),
          _buildSecondaryButton(
            icon: Icons.share_rounded,
            onPressed: () {
              // TODO: Implement share
            },
            isDark: isDark,
          ),
          _buildSecondaryButton(
            icon: Icons.speed_rounded,
            onPressed: () {
              _showSpeedControl(audioService, isDark);
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.15),
                ],
              )
            : null,
        border: isActive
            ? Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                width: 1.5,
              )
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 26,
          color: isActive
              ? Theme.of(context).primaryColor
              : (isDark ? Colors.white60 : Colors.black54),
        ),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  void _showSpeedControl(SimpleAudioService audioService, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1a1a3e), const Color(0xFF16213e)]
                  : [Colors.white, const Color(0xFFf8f9fa)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.2),
                          Theme.of(context).primaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.speed_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Playback Speed',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                  final isSelected = speed == 1.0; // TODO: Check actual speed
                  return InkWell(
                    onTap: () {
                      // TODO: Implement speed change
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              )
                            : LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ]
                                    : [
                                        Colors.black.withOpacity(0.05),
                                        Colors.black.withOpacity(0.02),
                                      ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.1)),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistView(SimpleAudioService audioService, bool isDark) {
    final playlist = audioService.playlist;
    final currentIndex = audioService.currentIndex;

    if (playlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 80,
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No playlist available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.03),
                      ]
                    : [
                        Colors.black.withOpacity(0.04),
                        Colors.black.withOpacity(0.02),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.2),
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Now Playing',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.length} tracks in queue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playlist.length,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final media = playlist[index];
              final isPlaying = index == currentIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: isPlaying
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.15),
                            Theme.of(context).primaryColor.withOpacity(0.08),
                          ],
                        )
                      : LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.02),
                                ]
                              : [
                                  Colors.black.withOpacity(0.03),
                                  Colors.black.withOpacity(0.01),
                                ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPlaying
                        ? Theme.of(context).primaryColor.withOpacity(0.4)
                        : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.08)),
                    width: 1.5,
                  ),
                  boxShadow: isPlaying
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isPlaying
                          ? LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            )
                          : LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.white.withOpacity(0.12),
                                      Colors.white.withOpacity(0.06),
                                    ]
                                  : [
                                      Colors.black.withOpacity(0.08),
                                      Colors.black.withOpacity(0.04),
                                    ],
                            ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPlaying
                            ? Colors.white.withOpacity(0.3)
                            : (isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.1)),
                        width: 1.5,
                      ),
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: isPlaying && audioService.isPlaying
                          ? Icon(
                              Icons.equalizer_rounded,
                              color: Colors.white,
                              size: 28,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: isPlaying
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    media.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 16,
                      color: isPlaying
                          ? Theme.of(context).primaryColor
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: isDark
                              ? Colors.white.withOpacity(0.4)
                              : Colors.black.withOpacity(0.4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Unknown Artist',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: isPlaying
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_circle_filled_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                        )
                      : Icon(
                          Icons.play_circle_outline_rounded,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                          size: 28,
                        ),
                  onTap: () {
                    // TODO: Play selected track
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
