import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/media_file.dart';
import '../widgets/video_controls.dart';
import '../widgets/professional_video_controls.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/admob_service.dart';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/playlist_provider.dart';
import '../utils/theme_colors.dart';
import '../screens/modern_audio_player.dart';
import '../screens/professional_audio_player.dart';
import '../services/simple_audio_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaFile media;
  final List<MediaFile>? playlist;
  final int? currentIndex;

  const VideoPlayerScreen({
    super.key,
    required this.media,
    this.playlist,
    this.currentIndex,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Timer? _hideControlsTimer;
  double _currentPosition = 0.0;
  double _duration = 0.0;
  double _playbackSpeed = 1.0;
  double _brightness = 0.5;
  double _volume = 0.5;

  // Gesture tracking
  bool _isDragging = false;
  bool _isSeekGesture = false;
  bool _isBrightnessGesture = false;
  bool _isVolumeGesture = false;
  double _gestureStartValue = 0.0;
  Offset? _gestureStartPosition;

  // Animation controllers
  late AnimationController _controlsAnimationController;
  late AnimationController _gestureAnimationController;
  late AnimationController _playPauseAnimationController;
  late Animation<double> _controlsAnimation;
  late Animation<double> _gestureAnimation;

  // Playlist navigation
  List<MediaFile>? _currentPlaylist;
  int _currentPlaylistIndex = 0;

  // Playback modes
  bool _isLooping = false;
  bool _isShuffling = false;

  // Double tap to seek
  bool _showDoubleTapFeedback = false;
  bool _isDoubleTapLeft = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Check if this is an audio file and redirect to audio player
    if (widget.media.type == MediaType.audio) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          List<MediaFile> audioPlaylist;
          int currentIndex;

          if (widget.playlist != null && widget.playlist!.isNotEmpty) {
            audioPlaylist = widget.playlist!;
            currentIndex = widget.currentIndex ?? 0;
          } else {
            audioPlaylist = await _createFolderPlaylist(widget.media);
            currentIndex = audioPlaylist.indexWhere(
              (file) => file.path == widget.media.path,
            );
            if (currentIndex == -1) currentIndex = 0;
          }

          SimpleAudioService.instance.playMedia(
            widget.media,
            playlist: audioPlaylist,
            index: currentIndex,
          );

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProfessionalAudioPlayer(
                    media: widget.media,
                    playlist: audioPlaylist,
                    currentIndex: currentIndex,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        } catch (e) {
          print('Failed to open audio player: $e');
          if (mounted) {
            _showStyledSnackBar('Audio player not available', isError: true);
          }
        }
      });
      return;
    }

    _initializePlaylist();
    _showInterstitialBeforeVideo();
    _initializePlayer();
    _getSystemValues();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _setupAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeOutCubic,
    );

    _gestureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _gestureAnimation = CurvedAnimation(
      parent: _gestureAnimationController,
      curve: Curves.easeOutCubic,
    );

    _playPauseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (_showControls) {
      _controlsAnimationController.forward();
    }
  }

  void _initializePlaylist() {
    if (widget.playlist != null) {
      _currentPlaylist = widget.playlist;
      _currentPlaylistIndex = widget.currentIndex ?? 0;
    } else {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      final allFiles = [
        ...mediaProvider.videoFiles,
        ...mediaProvider.audioFiles,
      ];

      if (allFiles.isNotEmpty) {
        _currentPlaylist = allFiles;
        _currentPlaylistIndex = allFiles.indexWhere(
          (file) => file.path == widget.media.path,
        );
        if (_currentPlaylistIndex == -1) _currentPlaylistIndex = 0;
      }
    }
  }

  void _showInterstitialBeforeVideo() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && AdMobService.isInterstitialAdAvailable) {
        AdMobService.showInterstitialAd();
      }
    });
  }

  Future<void> _getSystemValues() async {
    _brightness = 0.5;
    _volume = 0.5;
  }

  Future<void> _initializePlayer() async {
    try {
      if (kIsWeb) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.media.path),
        );
      } else {
        _controller = VideoPlayerController.file(File(widget.media.path));
      }

      _controller!.addListener(_videoListener);
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller!.value.duration.inMilliseconds.toDouble();
          _isPlaying = false;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _controller != null) {
            _controller!.play();
            _startHideControlsTimer();
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        _showStyledSnackBar('Error loading video', isError: true);
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    final value = _controller!.value;

    if (value.position >= value.duration && value.duration.inMilliseconds > 0) {
      _handleVideoFinished();
    }

    if (_isPlaying != value.isPlaying ||
        _isBuffering != value.isBuffering ||
        (_currentPosition - value.position.inMilliseconds.toDouble()).abs() >
            100) {
      setState(() {
        _isPlaying = value.isPlaying;
        _isBuffering = value.isBuffering;
        if (!_isDragging) {
          _currentPosition = value.position.inMilliseconds.toDouble();
        }
      });
    }
  }

  void _handleVideoFinished() {
    if (_isLooping) {
      _controller!.seekTo(Duration.zero);
      _controller!.play();
    } else if (_hasNext) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _playNext();
      });
    } else if (_isShuffling &&
        _currentPlaylist != null &&
        _currentPlaylist!.length > 1) {
      _playRandom();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && _isPlaying) {
        _hideControls();
      }
    });
  }

  void _showControlsTemporary() {
    if (!_showControls) {
      setState(() => _showControls = true);
      _controlsAnimationController.forward();
    }
    _startHideControlsTimer();
  }

  void _hideControls() {
    setState(() => _showControls = false);
    _controlsAnimationController.reverse();
  }

  void _toggleControls() {
    HapticFeedback.lightImpact();
    if (_showControls) {
      _hideControls();
    } else {
      _showControlsTemporary();
    }
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _gestureStartPosition = details.localPosition;
    final screenSize = MediaQuery.of(context).size;

    if (details.localPosition.dx < screenSize.width * 0.3) {
      _isBrightnessGesture = true;
      _gestureStartValue = _brightness;
    } else if (details.localPosition.dx > screenSize.width * 0.7) {
      _isVolumeGesture = true;
      _gestureStartValue = _volume;
    } else {
      _isSeekGesture = true;
      _gestureStartValue = _currentPosition;
    }

    _gestureAnimationController.forward();
    _hideControlsTimer?.cancel();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _gestureStartPosition == null || !_isInitialized)
      return;

    final delta = details.localPosition - _gestureStartPosition!;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isBrightnessGesture) {
      final newBrightness = (_gestureStartValue - (delta.dy / screenHeight))
          .clamp(0.0, 1.0);
      _setBrightness(newBrightness);
    } else if (_isVolumeGesture) {
      final newVolume = (_gestureStartValue - (delta.dy / screenHeight)).clamp(
        0.0,
        1.0,
      );
      _setVolume(newVolume);
    } else if (_isSeekGesture && _duration > 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      final seekDelta = (delta.dx / screenWidth) * _duration;
      final newPosition = (_gestureStartValue + seekDelta).clamp(
        0.0,
        _duration,
      );

      setState(() => _currentPosition = newPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSeekGesture && _controller != null && _isInitialized) {
      Future.delayed(const Duration(milliseconds: 100), () async {
        if (_controller != null && mounted) {
          try {
            await _controller!.seekTo(
              Duration(milliseconds: _currentPosition.toInt()),
            );
          } catch (e) {
            debugPrint('Seek error: $e');
            if (_controller != null) {
              setState(() {
                _currentPosition = _controller!.value.position.inMilliseconds
                    .toDouble();
              });
            }
          }
        }
      });
    }

    _isDragging = false;
    _isSeekGesture = false;
    _isBrightnessGesture = false;
    _isVolumeGesture = false;
    _gestureStartPosition = null;

    _gestureAnimationController.reverse();
    _startHideControlsTimer();
  }

  Future<void> _setBrightness(double value) async {
    setState(() => _brightness = value);
  }

  Future<void> _setVolume(double value) async {
    setState(() => _volume = value);
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    HapticFeedback.mediumImpact();
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });

    _playPauseAnimationController.forward(from: 0);
    _showControlsTemporary();
  }

  void _seek(double position) {
    if (_controller == null || !_isInitialized || _duration <= 0) return;

    final clampedPosition = position.clamp(0.0, _duration);
    setState(() => _currentPosition = clampedPosition);
    _debounceSeek(clampedPosition);
    _showControlsTemporary();
  }

  Timer? _seekTimer;
  void _debounceSeek(double position) {
    _seekTimer?.cancel();
    _seekTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_controller != null && mounted && _isInitialized) {
        try {
          await _controller!.seekTo(Duration(milliseconds: position.toInt()));
        } catch (e) {
          debugPrint('Debounced seek error: $e');
        }
      }
    });
  }

  void _setPlaybackSpeed(double speed) {
    if (_controller == null) return;
    HapticFeedback.selectionClick();
    _controller!.setPlaybackSpeed(speed);
    setState(() => _playbackSpeed = speed);
    _showStyledSnackBar('Speed: ${speed}x', isError: false);
  }

  // Double tap to seek
  void _handleDoubleTap(TapDownDetails details) {
    if (!_isInitialized) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.localPosition.dx < screenWidth / 2;

    HapticFeedback.mediumImpact();
    setState(() {
      _showDoubleTapFeedback = true;
      _isDoubleTapLeft = isLeftSide;
    });

    // Seek backward or forward
    final seekAmount = isLeftSide ? -10000.0 : 10000.0; // 10 seconds
    final newPosition = (_currentPosition + seekAmount).clamp(0.0, _duration);
    _seek(newPosition);

    // Hide feedback after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showDoubleTapFeedback = false);
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _seekTimer?.cancel();
    _controlsAnimationController.dispose();
    _gestureAnimationController.dispose();
    _playPauseAnimationController.dispose();
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _showInterstitialAfterVideo();
    super.dispose();
  }

  void _showInterstitialAfterVideo() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (AdMobService.isInterstitialAdAvailable) {
        AdMobService.showInterstitialAd();
      }
    });
  }

  bool get _hasNext =>
      _currentPlaylist != null &&
      _currentPlaylistIndex < _currentPlaylist!.length - 1;
  bool get _hasPrevious =>
      _currentPlaylist != null && _currentPlaylistIndex > 0;

  void _playNext() {
    if (_isShuffling &&
        _currentPlaylist != null &&
        _currentPlaylist!.length > 1) {
      _playRandom();
    } else if (_hasNext) {
      _currentPlaylistIndex++;
      _switchToMedia(_currentPlaylist![_currentPlaylistIndex]);
    }
  }

  void _playPrevious() {
    if (_isShuffling &&
        _currentPlaylist != null &&
        _currentPlaylist!.length > 1) {
      _playRandom();
    } else if (_hasPrevious) {
      _currentPlaylistIndex--;
      _switchToMedia(_currentPlaylist![_currentPlaylistIndex]);
    }
  }

  void _playRandom() {
    if (_currentPlaylist == null || _currentPlaylist!.length <= 1) return;

    int randomIndex;
    do {
      randomIndex =
          DateTime.now().millisecondsSinceEpoch % _currentPlaylist!.length;
    } while (randomIndex == _currentPlaylistIndex &&
        _currentPlaylist!.length > 1);

    _currentPlaylistIndex = randomIndex;
    _switchToMedia(_currentPlaylist![_currentPlaylistIndex]);
  }

  void _toggleLoop() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLooping = !_isLooping;
      if (_isLooping) _isShuffling = false;
    });
    _showStyledSnackBar(
      _isLooping ? 'Loop enabled' : 'Loop disabled',
      isError: false,
    );
  }

  void _toggleShuffle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isShuffling = !_isShuffling;
      if (_isShuffling) _isLooping = false;
    });
    _showStyledSnackBar(
      _isShuffling ? 'Shuffle enabled' : 'Shuffle disabled',
      isError: false,
    );
  }

  Future<void> _switchToMedia(MediaFile media) async {
    AdMobService.showInterstitialAdIfAvailable();

    await _controller?.dispose();
    _controller = null;

    setState(() {
      _isInitialized = false;
      _currentPosition = 0.0;
      _duration = 0.0;
    });

    try {
      if (kIsWeb) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(media.path));
      } else {
        _controller = VideoPlayerController.file(File(media.path));
      }
      await _controller!.initialize();
      _controller!.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration.inMilliseconds.toDouble();
      });

      _controller!.play();
      _startHideControlsTimer();
    } catch (e) {
      debugPrint('Error switching to media: $e');
      _showStyledSnackBar('Error loading video', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            _buildLoadingState(),

          // Gesture detector with double tap
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              onDoubleTapDown: _handleDoubleTap,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Double tap feedback
          if (_showDoubleTapFeedback) _buildDoubleTapFeedback(),

          // Buffering indicator
          if (_isBuffering) _buildBufferingIndicator(),

          // Gesture feedback overlays
          if (_isDragging) _buildGestureOverlay(),

          // Premium Controls
          _buildPremiumControls(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.3),
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading video...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const CircularProgressIndicator(
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildDoubleTapFeedback() {
    return Positioned.fill(
      child: Row(
        children: [
          // Left side (backward)
          Expanded(
            child: AnimatedOpacity(
              opacity: _isDoubleTapLeft ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fast_rewind_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '-10 seconds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right side (forward)
          Expanded(
            child: AnimatedOpacity(
              opacity: !_isDoubleTapLeft && _showDoubleTapFeedback ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fast_forward_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '+10 seconds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureOverlay() {
    return FadeTransition(
      opacity: _gestureAnimation,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: _buildGestureContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGestureContent() {
    if (_isBrightnessGesture) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brightness_6_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          Text(
            'Brightness',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_brightness * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildGestureProgressBar(_brightness, Colors.amber),
        ],
      );
    } else if (_isVolumeGesture) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _volume > 0.5
                ? Icons.volume_up_rounded
                : _volume > 0
                ? Icons.volume_down_rounded
                : Icons.volume_mute_rounded,
            color: Colors.blue,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Volume',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_volume * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildGestureProgressBar(_volume, Colors.blue),
        ],
      );
    } else if (_isSeekGesture) {
      final position = Duration(milliseconds: _currentPosition.toInt());
      final total = Duration(milliseconds: _duration.toInt());

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fast_forward_rounded,
            color: Colors.purple,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Seek',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDuration(position)} / ${_formatDuration(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildGestureProgressBar(_currentPosition / _duration, Colors.purple),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildGestureProgressBar(double value, Color color) {
    return Container(
      width: 200,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumControls() {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _controlsAnimation.value,
          child: _showControls
              ? _buildControlsContent()
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildControlsContent() {
    final currentMedia =
        _currentPlaylist != null && _currentPlaylist!.isNotEmpty
        ? _currentPlaylist![_currentPlaylistIndex]
        : widget.media;

    return Stack(
      children: [
        // Top gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
          ),
        ),
        // Bottom gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
              ),
            ),
          ),
        ),
        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildGlassButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentMedia.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentMedia.extension.toUpperCase()} • ${_formatDuration(Duration(milliseconds: _duration.toInt()))}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Consumer<PlaylistProvider>(
                    builder: (context, playlistProvider, child) {
                      final isFavorite = playlistProvider.isFavorite(currentMedia);
                      return _buildGlassButton(
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          if (isFavorite) {
                            await playlistProvider.removeFromFavorites(currentMedia);
                          } else {
                            await playlistProvider.addToFavorites(currentMedia);
                          }
                        },
                        isFavorite: isFavorite,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildGlassButton(
                    icon: Icons.more_vert_rounded,
                    onPressed: () => _showOptionsMenu(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Center play/pause button
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
              CurvedAnimation(
                parent: _playPauseAnimationController,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(
                  parent: _playPauseAnimationController,
                  curve: Curves.easeInCubic,
                ),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _togglePlayPause,
                    customBorder: const CircleBorder(),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  _buildProgressBar(),
                  const SizedBox(height: 16),
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.shuffle_rounded,
                        isActive: _isShuffling,
                        onPressed: _toggleShuffle,
                      ),
                      _buildControlButton(
                        icon: Icons.skip_previous_rounded,
                        isActive: _hasPrevious,
                        onPressed: _hasPrevious ? _playPrevious : null,
                      ),
                      _buildControlButton(
                        icon: Icons.replay_10_rounded,
                        isActive: true,
                        onPressed: () => _seek(_currentPosition - 10000),
                      ),
                      _buildLargeControlButton(
                        icon: _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onPressed: _togglePlayPause,
                      ),
                      _buildControlButton(
                        icon: Icons.forward_10_rounded,
                        isActive: true,
                        onPressed: () => _seek(_currentPosition + 10000),
                      ),
                      _buildControlButton(
                        icon: Icons.skip_next_rounded,
                        isActive: _hasNext,
                        onPressed: _hasNext ? _playNext : null,
                      ),
                      _buildControlButton(
                        icon: _isLooping
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        isActive: _isLooping,
                        onPressed: _toggleLoop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.purple,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayColor: Colors.purple.withOpacity(0.3),
          ),
          child: Slider(
            value: _duration > 0
                ? (_currentPosition / _duration).clamp(0.0, 1.0)
                : 0.0,
            onChanged: (value) {
              setState(() => _currentPosition = value * _duration);
            },
            onChangeEnd: (value) {
              _seek(value * _duration);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(
                  Duration(milliseconds: _currentPosition.toInt()),
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(Duration(milliseconds: _duration.toInt())),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isFavorite = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isFavorite
              ? [
                  Colors.pink.withOpacity(0.4),
                  Colors.red.withOpacity(0.3),
                ]
              : [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
        ),
        border: Border.all(
          color: isFavorite
              ? Colors.pink.withOpacity(0.6)
              : Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isFavorite
            ? [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: isFavorite ? Colors.pink : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.3),
                ],
              )
            : null,
        border: Border.all(
          color: Colors.white.withOpacity(isActive ? 0.5 : 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed();
                }
              : null,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLargeControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  icon: Icons.speed_rounded,
                  title: 'Playback Speed',
                  subtitle: '${_playbackSpeed}x',
                  onTap: () {
                    Navigator.pop(context);
                    _showSpeedMenu();
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.share_rounded,
                  title: 'Share Video',
                  subtitle: 'Share with friends',
                  onTap: () {
                    Navigator.pop(context);
                    _shareCurrentVideo();
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.playlist_play_rounded,
                  title: 'Playlist',
                  subtitle:
                      '${_currentPlaylistIndex + 1} of ${_currentPlaylist?.length ?? 1}',
                  onTap: () {
                    Navigator.pop(context);
                    // Show playlist
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeedMenu() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
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
                  children: speeds.map((speed) {
                    final isSelected = _playbackSpeed == speed;
                    return GestureDetector(
                      onTap: () {
                        _setPlaybackSpeed(speed);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Colors.purple, Colors.blue],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.purple
                                : Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
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
      ),
    );
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

  void _shareCurrentVideo() async {
    try {
      final currentMedia =
          _currentPlaylist != null && _currentPlaylist!.isNotEmpty
          ? _currentPlaylist![_currentPlaylistIndex]
          : widget.media;

      final file = File(currentMedia.path);
      if (await file.exists()) {
        final xFile = XFile(currentMedia.path);
        await Share.shareXFiles(
          [xFile],
          text: 'Check out this video: ${currentMedia.name}',
          subject: 'Sharing Video - ${currentMedia.name}',
        );
      } else {
        await Share.share(
          'Check out this video: ${currentMedia.name}',
          subject: 'Sharing Video - ${currentMedia.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showStyledSnackBar('Failed to share video', isError: true);
      }
    }
  }

  void _showStyledSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<List<MediaFile>> _createFolderPlaylist(MediaFile currentFile) async {
    try {
      final currentDir = Directory(currentFile.path).parent;
      final List<MediaFile> audioFiles = [];
      final List<String> supportedExtensions = [
        '.mp3',
        '.m4a',
        '.wav',
        '.flac',
        '.aac',
        '.ogg',
        '.wma',
      ];

      await for (final entity in currentDir.list()) {
        if (entity is File) {
          final extension = entity.path.toLowerCase().substring(
            entity.path.lastIndexOf('.'),
          );

          if (supportedExtensions.contains(extension)) {
            final stat = await entity.stat();
            final mediaFile = MediaFile(
              path: entity.path,
              name: entity.path.split(Platform.pathSeparator).last,
              extension: extension,
              size: stat.size,
              type: MediaType.audio,
              lastModified: stat.modified,
              dateAdded: stat.modified,
              duration: null,
            );
            audioFiles.add(mediaFile);
          }
        }
      }

      audioFiles.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return audioFiles.isNotEmpty ? audioFiles : [currentFile];
    } catch (e) {
      print('Error scanning folder: $e');
      return [currentFile];
    }
  }
}
