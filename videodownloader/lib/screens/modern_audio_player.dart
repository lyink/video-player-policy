import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_file.dart';
import '../providers/theme_provider.dart';
import '../providers/media_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/simple_audio_service.dart';
import '../services/admob_service.dart';

class ModernAudioPlayer extends StatefulWidget {
  final MediaFile media;
  final List<MediaFile>? playlist;
  final int? currentIndex;

  const ModernAudioPlayer({
    super.key,
    required this.media,
    this.playlist,
    this.currentIndex,
  });

  @override
  State<ModernAudioPlayer> createState() => _ModernAudioPlayerState();
}

class _ModernAudioPlayerState extends State<ModernAudioPlayer>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _playButtonController;
  late AnimationController _albumRotationController;
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _playButtonAnimation;
  late Animation<double> _albumRotationAnimation;
  late Animation<double> _pulseAnimation;

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
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _playButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
    );

    _albumRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _albumRotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    _albumRotationController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
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
          body: Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(isDark, audioService.isPlaying),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildAppBar(isDark),
                      const SizedBox(height: 30),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildAlbumArt(audioService.isPlaying, isDark),
                              const SizedBox(height: 50),
                              _buildSongInfo(audioService, isDark),
                              const SizedBox(height: 40),
                              _buildProgressBar(audioService, isDark),
                              const SizedBox(height: 50),
                              _buildControls(audioService, isDark),
                              const SizedBox(height: 40),
                              _buildSecondaryControls(audioService, isDark),
                              const SizedBox(height: 30),
                              _buildPlaylistInfo(audioService, isDark),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground(bool isDark, bool isPlaying) {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _shimmerController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0a0e27),
                      const Color(0xFF16213e),
                      const Color(0xFF1a1a3e),
                      const Color(0xFF0f1729),
                    ]
                  : [
                      const Color(0xFFfafafa),
                      const Color(0xFFf0f4f8),
                      const Color(0xFFe1e8ed),
                      const Color(0xFFf5f7fa),
                    ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated particles
              if (isPlaying)
                ...List.generate(8, (i) {
                  final offset = (i * 0.125) + _particleController.value;
                  final x =
                      (math.sin(offset * math.pi * 2) * 0.3 + 0.5) *
                      MediaQuery.of(context).size.width;
                  final y =
                      (math.cos(offset * math.pi * 1.5) * 0.4 + 0.5) *
                      MediaQuery.of(context).size.height;

                  return Positioned(
                    left: x,
                    top: y,
                    child: Container(
                      width: 120 + (i * 15.0),
                      height: 120 + (i * 15.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(
                              0.15 * _pulseAnimation.value,
                            ),
                            Theme.of(context).primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              // Shimmer overlay
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(
                              0.03 *
                                  math.sin(
                                    _shimmerController.value * math.pi * 2,
                                  ),
                            ),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: [
                            _shimmerController.value * 0.3,
                            _shimmerController.value * 0.5,
                            _shimmerController.value * 0.7,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final isFavorite = playlistProvider.isFavorite(widget.media);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.05),
                          ]
                        : [
                            Colors.black.withOpacity(0.08),
                            Colors.black.withOpacity(0.03),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    // Show interstitial ad when closing
                    AdMobService.showInterstitialAdIfAvailable();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 28,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              const Spacer(),

              // Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03),
                          ]
                        : [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.02),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Now Playing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Favorite button
              Container(
                decoration: BoxDecoration(
                  gradient: isFavorite
                      ? LinearGradient(
                          colors: [
                            Colors.pink.withOpacity(0.3),
                            Colors.red.withOpacity(0.2),
                          ],
                        )
                      : LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.05),
                                ]
                              : [
                                  Colors.black.withOpacity(0.08),
                                  Colors.black.withOpacity(0.03),
                                ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFavorite
                        ? Colors.pink.withOpacity(0.5)
                        : (isDark
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.1)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFavorite
                          ? Colors.pink.withOpacity(0.3)
                          : Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    if (isFavorite) {
                      await playlistProvider.removeFromFavorites(widget.media);
                    } else {
                      await playlistProvider.addToFavorites(widget.media);
                    }
                  },
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 24,
                    color: isFavorite
                        ? Colors.pink
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(bool isPlaying, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isPlaying ? _pulseAnimation.value : 1.0,
          child: Hero(
            tag: 'album_art_${widget.media.path}',
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 25),
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
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
                          angle: _albumRotationAnimation.value * 2 * math.pi,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.7),
                                  Theme.of(context).colorScheme.secondary,
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.7),
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.8),
                                  Theme.of(context).primaryColor,
                                ],
                                stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Glassmorphic overlay
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                              Colors.white.withOpacity(isDark ? 0.08 : 0.15),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(isDark ? 0.2 : 0.4),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    // Center content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated music icon
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isPlaying
                                    ? 1.0 + (_waveController.value * 0.12)
                                    : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.15),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),

                          if (isPlaying) ...[
                            const SizedBox(height: 28),
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
                            horizontal: 14,
                            vertical: 8,
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
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
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
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'PLAYING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveformIndicator() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (index) {
            final delay = index * 0.15;
            final animValue = (_waveController.value + delay) % 1.0;
            final height = 12 + (math.sin(animValue * math.pi * 2) * 12);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 5,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select an audio file to play',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Song title
        Text(
          currentMedia.name,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1.3,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 16),

        // Artist info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        if (audioService.playlist.length > 1) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.08),
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
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildProgressBar(SimpleAudioService audioService, bool isDark) {
    final position = audioService.position;
    final duration = audioService.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]
              : [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
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
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
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
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _formatDuration(position),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
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
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress slider
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Progress track
              FractionallySizedBox(
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
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Slider overlay
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 11,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final newPosition = Duration(
                      milliseconds: (value * duration.inMilliseconds).round(),
                    );
                    audioService.seekTo(newPosition);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(SimpleAudioService audioService, bool isDark) {
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
          size: 68,
          iconSize: 38,
          isDark: isDark,
        ),

        const SizedBox(width: 28),

        // Play/Pause button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isPlaying ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 95,
                height: 95,
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
                      color: Theme.of(context).primaryColor.withOpacity(0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: audioService.togglePlayPause,
                    borderRadius: BorderRadius.circular(48),
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
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 28),

        // Next button
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: canSkipNext ? audioService.skipNext : null,
          size: 68,
          iconSize: 38,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 68,
    double iconSize = 38,
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
                        Colors.white.withOpacity(0.06),
                      ]
                    : [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.04),
                      ])
              : [Colors.transparent, Colors.transparent],
        ),
        border: Border.all(
          color: onPressed != null
              ? (isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15))
              : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06)),
          width: 1.5,
        ),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.03)]
              : [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
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
              // TODO: Implement shuffle
            },
            isDark: isDark,
          ),
          _buildSecondaryButton(
            icon: Icons.repeat_rounded,
            onPressed: () {
              // TODO: Implement repeat
            },
            isDark: isDark,
          ),
          _buildSecondaryButton(
            icon: Icons.playlist_play_rounded,
            onPressed: () {
              // TODO: Show playlist
            },
            isDark: isDark,
          ),
          _buildSecondaryButton(
            icon: Icons.share_rounded,
            onPressed: () {
              // TODO: Share
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
    required bool isDark,
    bool isActive = false,
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

  Widget _buildPlaylistInfo(SimpleAudioService audioService, bool isDark) {
    final playlist = audioService.playlist;
    final currentIndex = audioService.currentIndex;

    if (playlist.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.15),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.queue_music_rounded,
              size: 22,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Playlist Mode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track ${currentIndex + 1} of ${playlist.length}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
