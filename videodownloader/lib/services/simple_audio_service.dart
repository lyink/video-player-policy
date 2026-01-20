import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/media_file.dart';
import 'background_audio_service.dart';

class SimpleAudioService extends ChangeNotifier {
  static final SimpleAudioService _instance = SimpleAudioService._internal();
  static SimpleAudioService get instance => _instance;

  SimpleAudioService._internal();

  BackgroundAudioService? _backgroundService;

  // Fallback audio player
  final AudioPlayer _fallbackPlayer = AudioPlayer();
  MediaFile? _fallbackCurrentMedia;
  List<MediaFile> _fallbackPlaylist = [];
  int _fallbackCurrentIndex = 0;
  bool _fallbackIsPlaying = false;
  Duration _fallbackPosition = Duration.zero;
  Duration _fallbackDuration = Duration.zero;

  // Stream subscriptions
  StreamSubscription? _mediaItemSubscription;
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _fallbackPositionSubscription;
  StreamSubscription? _fallbackDurationSubscription;
  StreamSubscription? _fallbackStateSubscription;

  // Getters
  MediaFile? get currentMedia => _backgroundService?.currentMedia ?? _fallbackCurrentMedia;
  List<MediaFile> get playlist => _backgroundService?.playlist ?? _fallbackPlaylist;
  int get currentIndex => _backgroundService?.currentIndex ?? _fallbackCurrentIndex;
  bool get isPlaying => _backgroundService?.isPlaying ?? _fallbackIsPlaying;
  Duration get position => _backgroundService?.position ?? _fallbackPosition;
  Duration get duration => _backgroundService?.duration ?? _fallbackDuration;
  bool get hasMedia => _backgroundService?.hasMedia ?? (_fallbackCurrentMedia != null);
  bool get canSkipNext => _backgroundService?.canSkipNext ?? (_fallbackCurrentIndex < _fallbackPlaylist.length - 1);
  bool get canSkipPrevious => _backgroundService?.canSkipPrevious ?? (_fallbackCurrentIndex > 0);

  Future<void> initialize() async {
    try {
      print('Initializing audio service...');
      _backgroundService = await AudioService.init(
        builder: () => BackgroundAudioService.instance,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.lyinkjr.videodownloader.audio',
          androidNotificationChannelName: 'Video Downloader Audio',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
          androidShowNotificationBadge: true,
          androidNotificationClickStartsActivity: true,
          androidNotificationIcon: 'drawable/ic_notification',
          fastForwardInterval: Duration(seconds: 15),
          rewindInterval: Duration(seconds: 15),
        ),
      );

      print('AudioService.init completed, initializing background service...');
      await _backgroundService!.initialize();
      _setupListeners();
      print('SimpleAudioService initialized successfully with background service');
    } catch (e, stackTrace) {
      print('Failed to initialize background audio service: $e');
      print('Stack trace: $stackTrace');
      // Try again with simpler config
      try {
        print('Trying simplified audio service config...');
        _backgroundService = await AudioService.init(
          builder: () => BackgroundAudioService.instance,
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'audio_playback',
            androidNotificationChannelName: 'Audio Playback',
            androidNotificationOngoing: false,
            androidStopForegroundOnPause: true,
            androidShowNotificationBadge: true,
            androidNotificationClickStartsActivity: true,
            androidNotificationIcon: 'drawable/ic_notification',
          ),
        );
        await _backgroundService!.initialize();
        _setupListeners();
        print('Simplified audio service initialized successfully');
      } catch (e2) {
        print('Simplified audio service also failed: $e2');
        _backgroundService = null;
        _setupFallbackPlayer();
      }
    }
  }

  void _setupFallbackPlayer() {
    print('Setting up fallback audio player...');

    _fallbackPositionSubscription = _fallbackPlayer.positionStream.listen((position) {
      _fallbackPosition = position;
      notifyListeners();
    });

    _fallbackDurationSubscription = _fallbackPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _fallbackDuration = duration;
        notifyListeners();
      }
    });

    _fallbackStateSubscription = _fallbackPlayer.playerStateStream.listen((state) {
      _fallbackIsPlaying = state.playing;
      notifyListeners();
    });

    print('Fallback audio player initialized');
  }

  void _setupListeners() {
    if (_backgroundService == null) return;

    // Listen to media item changes
    _mediaItemSubscription = _backgroundService!.mediaItem.listen((mediaItem) {
      notifyListeners();
    });

    // Listen to playback state changes
    _playbackStateSubscription = _backgroundService!.playbackState.listen((state) {
      notifyListeners();
    });
  }

  Future<void> playMedia(MediaFile media, {List<MediaFile>? playlist, int? index}) async {
    if (_backgroundService != null) {
      try {
        await _backgroundService!.playMedia(media, playlist: playlist, index: index);
        return;
      } catch (e) {
        print('Error playing media with background service: $e');
        print('Falling back to simple player...');
      }
    }

    // Use fallback player
    try {
      print('Playing media with fallback player: ${media.name}');
      _fallbackCurrentMedia = media;
      _fallbackPlaylist = playlist ?? [media];
      _fallbackCurrentIndex = index ?? 0;
      await _fallbackPlayer.setFilePath(media.path);
      await _fallbackPlayer.play();
      notifyListeners();
    } catch (e) {
      print('Error playing media with fallback player: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_backgroundService != null) {
      try {
        if (isPlaying) {
          await _backgroundService!.pause();
        } else {
          await _backgroundService!.play();
        }
        return;
      } catch (e) {
        print('Error toggling playback with background service: $e');
      }
    }

    // Use fallback player
    try {
      if (_fallbackIsPlaying) {
        await _fallbackPlayer.pause();
      } else {
        await _fallbackPlayer.play();
      }
    } catch (e) {
      print('Error toggling playback with fallback player: $e');
    }
  }

  Future<void> skipNext() async {
    if (_backgroundService != null) {
      await _backgroundService!.skipToNext();
    } else {
      // Fallback implementation for when background service is not available
      if (_fallbackCurrentIndex < _fallbackPlaylist.length - 1) {
        _fallbackCurrentIndex++;
        _fallbackCurrentMedia = _fallbackPlaylist[_fallbackCurrentIndex];
        await _fallbackPlayer.setFilePath(_fallbackCurrentMedia!.path);
        await _fallbackPlayer.play();
        notifyListeners();
        print('Fallback player: Skipped to next track - ${_fallbackCurrentMedia!.name}');
      } else {
        print('Cannot skip next: at end of playlist');
      }
    }
  }

  Future<void> skipPrevious() async {
    if (_backgroundService != null) {
      await _backgroundService!.skipToPrevious();
    } else {
      // Fallback implementation for when background service is not available
      if (_fallbackCurrentIndex > 0) {
        _fallbackCurrentIndex--;
        _fallbackCurrentMedia = _fallbackPlaylist[_fallbackCurrentIndex];
        await _fallbackPlayer.setFilePath(_fallbackCurrentMedia!.path);
        await _fallbackPlayer.play();
        notifyListeners();
        print('Fallback player: Skipped to previous track - ${_fallbackCurrentMedia!.name}');
      } else {
        print('Cannot skip previous: at beginning of playlist');
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_backgroundService != null) {
      await _backgroundService!.seek(position);
    } else {
      await _fallbackPlayer.seek(position);
    }
  }

  Future<void> stop() async {
    if (_backgroundService != null) {
      await _backgroundService!.stop();
    } else {
      await _fallbackPlayer.stop();
      _fallbackCurrentMedia = null;
      _fallbackPlaylist.clear();
      _fallbackCurrentIndex = 0;
      _fallbackIsPlaying = false;
      _fallbackPosition = Duration.zero;
      _fallbackDuration = Duration.zero;
      notifyListeners();
    }
  }

  void dispose() {
    _mediaItemSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _fallbackPositionSubscription?.cancel();
    _fallbackDurationSubscription?.cancel();
    _fallbackStateSubscription?.cancel();
    _backgroundService?.dispose();
    _fallbackPlayer.dispose();
    super.dispose();
  }
}