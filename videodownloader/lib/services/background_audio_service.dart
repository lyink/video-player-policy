import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../models/media_file.dart';

class BackgroundAudioService extends BaseAudioHandler with QueueHandler, SeekHandler {
  static BackgroundAudioService? _instance;
  static BackgroundAudioService get instance => _instance ??= BackgroundAudioService._internal();

  BackgroundAudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Current state
  MediaFile? _currentMedia;
  List<MediaFile> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Getters
  MediaFile? get currentMedia => _currentMedia;
  List<MediaFile> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasMedia => _currentMedia != null;
  bool get canSkipNext => _currentIndex < _playlist.length - 1;
  bool get canSkipPrevious => _currentIndex > 0;

  Future<void> initialize() async {
    // Listen to player events
    _player.positionStream.listen((position) {
      _position = position;
      _broadcastState();
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        _broadcastState();
      }
    });

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _broadcastState();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Auto-skip to next track when current track ends
        if (canSkipNext) {
          skipToNext();
        } else {
          // Stop playback when playlist ends
          stop();
        }
      }
    });

    print('Background audio service initialized');
  }

  Future<void> playMedia(MediaFile media, {List<MediaFile>? playlist, int? index}) async {
    try {
      _currentMedia = media;
      _playlist = playlist ?? [media];
      _currentIndex = index ?? 0;

      // Set up audio source
      await _player.setFilePath(media.path);

      // Update media item for notification
      await _updateMediaItem();

      // Start playing
      await _player.play();

      print('Background audio service: Started playing ${media.name}');
    } catch (e) {
      print('Error playing media: $e');
    }
  }

  @override
  Future<void> play() async {
    print('Background service: Play called');
    await _player.play();
  }

  @override
  Future<void> pause() async {
    print('Background service: Pause called');
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    print('Background service: Stop called');
    await _player.stop();
    _currentMedia = null;
    _playlist.clear();
    _currentIndex = 0;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;

    // Clear notification
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    print('Background service: Skip to next called');
    if (canSkipNext) {
      _currentIndex++;
      _currentMedia = _playlist[_currentIndex];
      await _player.setFilePath(_currentMedia!.path);
      await _updateMediaItem();
      await _player.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    print('Background service: Skip to previous called');
    if (canSkipPrevious) {
      _currentIndex--;
      _currentMedia = _playlist[_currentIndex];
      await _player.setFilePath(_currentMedia!.path);
      await _updateMediaItem();
      await _player.play();
    }
  }

  Future<void> _updateMediaItem() async {
    if (_currentMedia == null) return;

    final mediaItem = MediaItem(
      id: _currentMedia!.path,
      album: 'Unknown Album',
      title: _currentMedia!.name,
      artist: 'Unknown Artist',
      duration: _duration.inMicroseconds > 0 ? _duration : null,
      artUri: null, // You can add artwork URI here
      playable: true,
      extras: {
        'path': _currentMedia!.path,
        'index': _currentIndex,
        'totalTracks': _playlist.length,
      },
    );

    this.mediaItem.add(mediaItem);
    print('Updated media item: ${mediaItem.title}');
  }

  void _broadcastState() {
    final controls = <MediaControl>[];

    if (canSkipPrevious) {
      controls.add(MediaControl.skipToPrevious);
    }

    if (_isPlaying) {
      controls.add(MediaControl.pause);
    } else {
      controls.add(MediaControl.play);
    }

    if (canSkipNext) {
      controls.add(MediaControl.skipToNext);
    }

    final state = PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: canSkipPrevious && canSkipNext
          ? [0, 1, 2]  // Previous, Play/Pause, Next
          : canSkipNext
              ? [0, 1]  // Play/Pause, Next
              : [0],    // Just Play/Pause
      processingState: _mapProcessingState(_player.processingState),
      playing: _isPlaying,
      updatePosition: _position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    );

    playbackState.add(state);
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // Continue playing when app is removed from recent apps
    // Don't stop the service
    print('App task removed - continuing playback');
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Stop playback when notification is dismissed
    await stop();
  }

  void dispose() {
    _player.dispose();
  }
}