import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/media_file.dart';

/// Premium VLC-style Playlist Provider
/// Manages playlists, play queue, and playback settings with sophisticated features
class PlaylistProvider extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE STATE
  // ═══════════════════════════════════════════════════════════════════════════

  List<Playlist> _playlists = [];
  List<MediaFile> _playQueue = [];
  List<MediaFile> _queueHistory = [];
  List<int> _shuffleOrder = [];

  int _currentQueueIndex = 0;
  int _shuffleIndex = 0;
  int _maxHistorySize = 50;

  bool _shuffle = false;
  bool _autoPlayNext = true;
  bool _crossfade = false;

  int _crossfadeDuration = 3; // seconds
  double _playbackSpeed = 1.0;

  RepeatMode _repeatMode = RepeatMode.off;
  PlaybackOrder _playbackOrder = PlaybackOrder.default_;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  // Playlist Collections
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Playlist> get manualPlaylists =>
      _playlists.where((p) => p.type == PlaylistType.manual).toList();
  List<Playlist> get smartPlaylists =>
      _playlists.where((p) => p.type == PlaylistType.smart).toList();
  List<Playlist> get systemPlaylists =>
      _playlists.where((p) => p.type.isSystemPlaylist).toList();

  // System Playlists
  Playlist? get favoritesPlaylist =>
      _findSystemPlaylist(PlaylistType.favorites);
  Playlist? get recentPlaylist => _findSystemPlaylist(PlaylistType.recent);
  Playlist? get mostPlayedPlaylist =>
      _findSystemPlaylist(PlaylistType.mostPlayed);
  Playlist? get neverPlayedPlaylist =>
      _findSystemPlaylist(PlaylistType.neverPlayed);

  // Play Queue
  List<MediaFile> get playQueue => List.unmodifiable(_playQueue);
  List<MediaFile> get queueHistory => List.unmodifiable(_queueHistory);
  int get currentQueueIndex => _currentQueueIndex;
  MediaFile? get currentMedia =>
      _playQueue.isNotEmpty && _currentQueueIndex < _playQueue.length
      ? _playQueue[_currentQueueIndex]
      : null;

  // Playback Settings
  bool get shuffle => _shuffle;
  bool get autoPlayNext => _autoPlayNext;
  bool get crossfade => _crossfade;
  int get crossfadeDuration => _crossfadeDuration;
  double get playbackSpeed => _playbackSpeed;
  RepeatMode get repeatMode => _repeatMode;
  PlaybackOrder get playbackOrder => _playbackOrder;

  // Convenience Getters
  bool get hasQueue => _playQueue.isNotEmpty;
  bool get canPlayNext => _currentQueueIndex < _playQueue.length - 1;
  bool get canPlayPrevious => _currentQueueIndex > 0;
  bool get repeat => _repeatMode != RepeatMode.off;
  bool get repeatOne => _repeatMode == RepeatMode.one;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  PlaylistProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadFromStorage();
    await _ensureSystemPlaylists();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEM PLAYLIST MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _ensureSystemPlaylists() async {
    final systemPlaylistConfigs = [
      _SystemPlaylistConfig(
        type: PlaylistType.favorites,
        name: '⭐ Favorites',
        description: 'Your favorite media files',
        icon: Icons.favorite,
        color: Colors.pink,
        position: 0,
      ),
      _SystemPlaylistConfig(
        type: PlaylistType.recent,
        name: '🕐 Recently Played',
        description: 'Recently played media files',
        icon: Icons.history,
        color: Colors.blue,
        maxItems: 100,
        position: 1,
      ),
      _SystemPlaylistConfig(
        type: PlaylistType.mostPlayed,
        name: '🔥 Most Played',
        description: 'Your most played tracks',
        icon: Icons.trending_up,
        color: Colors.orange,
        maxItems: 50,
        sortBy: PlaylistSortBy.playCount,
        sortOrder: SortOrder.descending,
        position: 2,
      ),
      _SystemPlaylistConfig(
        type: PlaylistType.neverPlayed,
        name: '🆕 Never Played',
        description: 'Tracks you haven\'t played yet',
        icon: Icons.fiber_new,
        color: Colors.green,
        position: 3,
      ),
    ];

    bool hasChanges = false;
    for (final config in systemPlaylistConfigs) {
      if (!_playlists.any((p) => p.type == config.type)) {
        _createSystemPlaylist(config);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveToStorage();
    }
  }

  void _createSystemPlaylist(_SystemPlaylistConfig config) {
    final playlist = Playlist(
      id: config.type.name,
      name: config.name,
      description: config.description,
      type: config.type,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      icon: config.icon,
      color: config.color,
      isSystem: true,
      maxItems: config.maxItems,
      sortBy: config.sortBy,
      sortOrder: config.sortOrder,
    );

    _playlists.insert(config.position, playlist);
  }

  Playlist? _findSystemPlaylist(PlaylistType type) {
    try {
      return _playlists.firstWhere((p) => p.type == type);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYLIST CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new manual playlist
  Future<Playlist> createManualPlaylist({
    required String name,
    String description = '',
    List<MediaFile> initialFiles = const [],
    IconData? icon,
    Color? color,
  }) async {
    final playlist = Playlist.createManual(
      name: name,
      description: description,
      initialFiles: initialFiles,
      icon: icon ?? Icons.playlist_play,
      color: color,
    );

    _playlists.add(playlist);
    await _saveToStorage();
    notifyListeners();
    return playlist;
  }

  /// Creates a new smart playlist with auto-updating rules
  Future<Playlist> createSmartPlaylist({
    required String name,
    required List<SmartPlaylistRule> rules,
    String description = '',
    PlaylistSortBy sortBy = PlaylistSortBy.name,
    SortOrder sortOrder = SortOrder.ascending,
    int maxItems = 1000,
    bool isAutoUpdate = true,
    IconData? icon,
    Color? color,
  }) async {
    final playlist = Playlist.createSmart(
      name: name,
      rules: rules,
      description: description,
      sortBy: sortBy,
      sortOrder: sortOrder,
      maxItems: maxItems,
      isAutoUpdate: isAutoUpdate,
      icon: icon ?? Icons.auto_awesome,
      color: color,
    );

    _playlists.add(playlist);
    await _saveToStorage();
    notifyListeners();
    return playlist;
  }

  /// Creates a playlist from a predefined template
  Future<Playlist> createFromTemplate(PlaylistTemplate template) async {
    final playlist = template.createPlaylist();
    _playlists.add(playlist);
    await _saveToStorage();
    notifyListeners();
    return playlist;
  }

  /// Updates an existing playlist
  Future<void> updatePlaylist(
    String playlistId,
    Playlist updatedPlaylist,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    _playlists[index] = updatedPlaylist.copyWith(lastModified: DateTime.now());

    await _saveToStorage();
    notifyListeners();
  }

  /// Deletes a playlist (cannot delete system playlists)
  Future<void> deletePlaylist(String playlistId) async {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => throw PlaylistException('Playlist not found'),
    );

    if (playlist.isSystem) {
      throw PlaylistException('Cannot delete system playlists');
    }

    _playlists.removeWhere((p) => p.id == playlistId);
    await _saveToStorage();
    notifyListeners();
  }

  /// Creates a duplicate of an existing playlist
  Future<Playlist> duplicatePlaylist(String playlistId) async {
    final original = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => throw PlaylistException('Playlist not found'),
    );

    final duplicate = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      isSystem: false,
    );

    _playlists.add(duplicate);
    await _saveToStorage();
    notifyListeners();
    return duplicate;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYLIST ITEM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adds media files to a playlist
  Future<bool> addToPlaylist(
    String playlistId,
    List<MediaFile> mediaFiles, {
    bool showFeedback = true,
  }) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return false;

    final playlist = _playlists[index];

    // Validate system playlist restrictions
    if (playlist.isSystem && playlist.type != PlaylistType.favorites) {
      return false;
    }

    final updatedItems = List<PlaylistItem>.from(playlist.items);
    final now = DateTime.now();
    int addedCount = 0;

    for (final mediaFile in mediaFiles) {
      if (!_itemExists(updatedItems, mediaFile.path)) {
        updatedItems.add(
          PlaylistItem(
            mediaFile: mediaFile,
            dateAdded: now,
            position: updatedItems.length,
          ),
        );
        addedCount++;
      }
    }

    if (addedCount > 0) {
      _playlists[index] = playlist.copyWith(
        items: updatedItems,
        lastModified: now,
      );

      await _saveToStorage();
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Removes media files from a playlist
  Future<void> removeFromPlaylist(
    String playlistId,
    List<String> mediaPaths,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];

    // Validate system playlist restrictions
    if (playlist.isSystem && playlist.type != PlaylistType.favorites) {
      return;
    }

    final updatedItems = playlist.items
        .where((item) => !mediaPaths.contains(item.mediaFile.path))
        .toList();

    // Reindex positions
    final reindexedItems = _reindexPlaylistItems(updatedItems);

    _playlists[index] = playlist.copyWith(
      items: reindexedItems,
      lastModified: DateTime.now(),
    );

    await _saveToStorage();
    notifyListeners();
  }

  /// Reorders items in a manual playlist
  Future<void> reorderPlaylistItems(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];

    // Only allow reordering in manual playlists
    if (playlist.type != PlaylistType.manual) return;

    final updatedItems = List<PlaylistItem>.from(playlist.items);

    // Adjust newIndex for Flutter's ReorderableListView behavior
    if (oldIndex < newIndex) newIndex -= 1;

    final item = updatedItems.removeAt(oldIndex);
    updatedItems.insert(newIndex, item);

    // Reindex positions
    final reindexedItems = _reindexPlaylistItems(updatedItems);

    _playlists[index] = playlist.copyWith(
      items: reindexedItems,
      lastModified: DateTime.now(),
    );

    await _saveToStorage();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMART PLAYLIST AUTO-UPDATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Updates all auto-updating smart playlists
  Future<void> updateSmartPlaylists(List<MediaFile> allMediaFiles) async {
    bool hasChanges = false;

    for (int i = 0; i < _playlists.length; i++) {
      final playlist = _playlists[i];
      List<PlaylistItem>? newItems;

      switch (playlist.type) {
        case PlaylistType.smart:
          if (playlist.isAutoUpdate) {
            newItems = _generateSmartPlaylistItems(playlist, allMediaFiles);
          }
          break;

        case PlaylistType.mostPlayed:
          newItems = _generateMostPlayedItems(allMediaFiles, playlist.maxItems);
          break;

        case PlaylistType.neverPlayed:
          newItems = _generateNeverPlayedItems(allMediaFiles);
          break;

        default:
          continue;
      }

      if (newItems != null && !_areItemListsEqual(playlist.items, newItems)) {
        _playlists[i] = playlist.copyWith(
          items: newItems,
          lastModified: DateTime.now(),
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveToStorage();
      notifyListeners();
    }
  }

  List<PlaylistItem> _generateSmartPlaylistItems(
    Playlist playlist,
    List<MediaFile> allMediaFiles,
  ) {
    final matchingFiles = allMediaFiles.where((file) {
      return playlist.smartRules.every((rule) => rule.matches(file));
    }).toList();

    final sortedFiles = _sortMediaFiles(
      matchingFiles,
      playlist.sortBy,
      playlist.sortOrder,
    );

    return _createPlaylistItems(sortedFiles.take(playlist.maxItems).toList());
  }

  List<PlaylistItem> _generateMostPlayedItems(
    List<MediaFile> allMediaFiles,
    int maxItems,
  ) {
    final playedFiles = allMediaFiles.where((f) => f.playCount > 0).toList();
    playedFiles.sort((a, b) => b.playCount.compareTo(a.playCount));
    return _createPlaylistItems(playedFiles.take(maxItems).toList());
  }

  List<PlaylistItem> _generateNeverPlayedItems(List<MediaFile> allMediaFiles) {
    final unplayedFiles = allMediaFiles.where((f) => f.playCount == 0).toList();
    return _createPlaylistItems(unplayedFiles);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAY QUEUE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sets the entire play queue
  void setPlayQueue(List<MediaFile> queue, {int startIndex = 0}) {
    _playQueue = List.from(queue);
    _currentQueueIndex = startIndex.clamp(0, max(0, _playQueue.length - 1));
    _generateShuffleOrder();
    _saveToStorage();
    notifyListeners();
  }

  /// Adds media files to the queue
  void addToQueue(List<MediaFile> mediaFiles, {bool playNext = false}) {
    if (playNext && _playQueue.isNotEmpty) {
      _playQueue.insertAll(_currentQueueIndex + 1, mediaFiles);
    } else {
      _playQueue.addAll(mediaFiles);
    }

    _generateShuffleOrder();
    _saveToStorage();
    notifyListeners();
  }

  /// Removes items from the queue by indices
  void removeFromQueue(List<int> indices) {
    // Sort in descending order to avoid index shifting
    indices.sort((a, b) => b.compareTo(a));

    for (final index in indices) {
      if (index < _playQueue.length) {
        _playQueue.removeAt(index);

        // Adjust current index
        if (index < _currentQueueIndex) {
          _currentQueueIndex--;
        } else if (index == _currentQueueIndex) {
          _currentQueueIndex = _currentQueueIndex.clamp(
            0,
            max(0, _playQueue.length - 1),
          );
        }
      }
    }

    _generateShuffleOrder();
    _saveToStorage();
    notifyListeners();
  }

  /// Clears the entire play queue
  void clearQueue() {
    _playQueue.clear();
    _currentQueueIndex = 0;
    _shuffleOrder.clear();
    _shuffleIndex = 0;
    _saveToStorage();
    notifyListeners();
  }

  /// Reorders items in the play queue
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    final item = _playQueue.removeAt(oldIndex);
    _playQueue.insert(newIndex, item);

    // Update current index if needed
    _currentQueueIndex = _updateCurrentIndexAfterReorder(
      _currentQueueIndex,
      oldIndex,
      newIndex,
    );

    _generateShuffleOrder();
    _saveToStorage();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYBACK CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Advances to the next track
  void next() {
    if (_playQueue.isEmpty) return;

    _addCurrentToHistory();

    if (_shuffle) {
      _shuffleIndex = (_shuffleIndex + 1) % _shuffleOrder.length;
      _currentQueueIndex = _shuffleOrder[_shuffleIndex];
    } else {
      if (canPlayNext) {
        _currentQueueIndex++;
      } else if (_repeatMode == RepeatMode.all) {
        _currentQueueIndex = 0;
      }
    }

    _saveToStorage();
    notifyListeners();
  }

  /// Goes back to the previous track
  void previous() {
    if (_playQueue.isEmpty) return;

    if (_shuffle) {
      _shuffleIndex =
          (_shuffleIndex - 1 + _shuffleOrder.length) % _shuffleOrder.length;
      _currentQueueIndex = _shuffleOrder[_shuffleIndex];
    } else {
      if (canPlayPrevious) {
        _currentQueueIndex--;
      } else if (_repeatMode == RepeatMode.all) {
        _currentQueueIndex = _playQueue.length - 1;
      }
    }

    _saveToStorage();
    notifyListeners();
  }

  /// Jumps to a specific index in the queue
  void jumpTo(int index) {
    if (index < 0 || index >= _playQueue.length) return;

    if (_currentQueueIndex != index) {
      _addCurrentToHistory();
    }

    _currentQueueIndex = index;

    if (_shuffle) {
      _shuffleIndex = _shuffleOrder.indexOf(index);
    }

    _saveToStorage();
    notifyListeners();
  }

  /// Cycles through repeat modes: Off → All → One → Off
  void toggleRepeat() {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };

    _saveToStorage();
    notifyListeners();
  }

  /// Sets a specific repeat mode
  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _saveToStorage();
    notifyListeners();
  }

  /// Toggles shuffle mode
  void toggleShuffle() {
    _shuffle = !_shuffle;

    if (_shuffle) {
      _generateShuffleOrder();
      _shuffleIndex = _shuffleOrder.indexOf(_currentQueueIndex);
    }

    _saveToStorage();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYBACK SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sets playback speed (0.25x to 4.0x)
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.25, 4.0);
    _saveToStorage();
    notifyListeners();
  }

  /// Toggles auto-play next track
  void setAutoPlayNext(bool value) {
    _autoPlayNext = value;
    _saveToStorage();
    notifyListeners();
  }

  /// Toggles crossfade between tracks
  void setCrossfade(bool value) {
    _crossfade = value;
    _saveToStorage();
    notifyListeners();
  }

  /// Sets crossfade duration (1-10 seconds)
  void setCrossfadeDuration(int seconds) {
    _crossfadeDuration = seconds.clamp(1, 10);
    _saveToStorage();
    notifyListeners();
  }

  /// Sets playback order
  void setPlaybackOrder(PlaybackOrder order) {
    _playbackOrder = order;
    _saveToStorage();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAVORITES MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adds a media file to favorites
  Future<void> addToFavorites(MediaFile mediaFile) async {
    final favPlaylist = favoritesPlaylist;
    if (favPlaylist != null) {
      await addToPlaylist(favPlaylist.id, [mediaFile]);
    }
  }

  /// Removes a media file from favorites
  Future<void> removeFromFavorites(MediaFile mediaFile) async {
    final favPlaylist = favoritesPlaylist;
    if (favPlaylist != null) {
      await removeFromPlaylist(favPlaylist.id, [mediaFile.path]);
    }
  }

  /// Toggles favorite status
  Future<void> toggleFavorite(MediaFile mediaFile) async {
    if (isFavorite(mediaFile)) {
      await removeFromFavorites(mediaFile);
    } else {
      await addToFavorites(mediaFile);
    }
  }

  /// Checks if a media file is favorited
  bool isFavorite(MediaFile mediaFile) {
    return favoritesPlaylist?.items.any(
          (item) => item.mediaFile.path == mediaFile.path,
        ) ??
        false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT HISTORY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adds a media file to recently played
  Future<void> addToRecent(MediaFile mediaFile) async {
    final playlist = recentPlaylist;
    if (playlist == null) return;

    // Remove if already exists
    await removeFromPlaylist(playlist.id, [mediaFile.path]);

    // Add to beginning
    final updatedItems = [
      PlaylistItem(
        mediaFile: mediaFile,
        dateAdded: DateTime.now(),
        position: 0,
      ),
      ...playlist.items.map(
        (item) => PlaylistItem(
          mediaFile: item.mediaFile,
          dateAdded: item.dateAdded,
          position: item.position + 1,
        ),
      ),
    ];

    // Limit to maxItems
    final limitedItems = updatedItems.take(playlist.maxItems).toList();

    await updatePlaylist(
      playlist.id,
      playlist.copyWith(items: limitedItems, lastModified: DateTime.now()),
    );
  }

  /// Clears queue history
  void clearHistory() {
    _queueHistory.clear();
    _saveToStorage();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMPORT/EXPORT FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Imports a playlist from a file (M3U, PLS, XSPF)
  Future<Playlist?> importPlaylistFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final extension = file.path.split('.').last.toLowerCase();

      final filePaths = switch (extension) {
        'm3u' || 'm3u8' => _parseM3U(content),
        'pls' => _parsePLS(content),
        'xspf' => _parseXSPF(content),
        _ => throw PlaylistException('Unsupported format: $extension'),
      };

      // Convert file paths to MediaFile objects
      final mediaFiles = <MediaFile>[];
      for (final path in filePaths) {
        final file = File(path);
        if (await file.exists()) {
          mediaFiles.add(MediaFile.fromFile(file));
        }
      }

      if (mediaFiles.isEmpty) {
        throw PlaylistException('No valid media files found');
      }

      // Create playlist
      final playlistName = file.path.split('/').last.split('.').first;
      return await createManualPlaylist(
        name: playlistName,
        description: 'Imported from ${file.path}',
        initialFiles: mediaFiles,
      );
    } catch (e) {
      debugPrint('Error importing playlist: $e');
      return null;
    }
  }

  /// Exports a playlist to a file
  Future<bool> exportPlaylistToFile(
    String playlistId,
    String filePath,
    String format,
  ) async {
    try {
      final playlist = _playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => throw PlaylistException('Playlist not found'),
      );

      final content = switch (format.toLowerCase()) {
        'm3u' || 'm3u8' => playlist.toM3U(),
        'pls' => playlist.toPLS(),
        'xspf' => playlist.toXSPF(),
        _ => throw PlaylistException('Unsupported format: $format'),
      };

      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      debugPrint('Error exporting playlist: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Merges multiple playlists into one
  Future<Playlist> mergePlaylists(
    List<String> playlistIds,
    String newName,
  ) async {
    final allItems = <PlaylistItem>[];

    for (final id in playlistIds) {
      final playlist = _playlists.firstWhere((p) => p.id == id);
      allItems.addAll(playlist.items);
    }

    // Remove duplicates
    final uniqueItems = _removeDuplicateItems(allItems);

    return await createManualPlaylist(
      name: newName,
      description: 'Merged from ${playlistIds.length} playlists',
      initialFiles: uniqueItems.map((i) => i.mediaFile).toList(),
    );
  }

  /// Gets statistics for a playlist
  PlaylistStats getPlaylistStats(String playlistId) {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => throw PlaylistException('Playlist not found'),
    );

    int totalDuration = 0;
    int totalSize = 0;
    int videoCount = 0;
    int audioCount = 0;

    for (final item in playlist.items) {
      totalDuration += (item.mediaFile.duration?.inSeconds ?? 0);
      totalSize += (item.mediaFile.size ?? 0);

      if (item.mediaFile.type == MediaType.video) {
        videoCount++;
      } else if (item.mediaFile.type == MediaType.audio) {
        audioCount++;
      }
    }

    return PlaylistStats(
      totalItems: playlist.items.length,
      totalDuration: Duration(seconds: totalDuration),
      totalSize: totalSize,
      videoCount: videoCount,
      audioCount: audioCount,
      createdAt: playlist.createdAt,
      lastModified: playlist.lastModified,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _generateShuffleOrder() {
    if (_playQueue.isEmpty) return;

    _shuffleOrder = List.generate(_playQueue.length, (i) => i);
    _shuffleOrder.shuffle(Random());
    _shuffleIndex = _shuffleOrder.indexOf(_currentQueueIndex);
  }

  void _addCurrentToHistory() {
    if (currentMedia != null) {
      _queueHistory.insert(0, currentMedia!);
      if (_queueHistory.length > _maxHistorySize) {
        _queueHistory.removeLast();
      }
    }
  }

  int _updateCurrentIndexAfterReorder(int current, int oldIdx, int newIdx) {
    if (oldIdx == current) {
      return newIdx;
    } else if (oldIdx < current && newIdx >= current) {
      return current - 1;
    } else if (oldIdx > current && newIdx <= current) {
      return current + 1;
    }
    return current;
  }

  List<PlaylistItem> _createPlaylistItems(List<MediaFile> files) {
    return files.asMap().entries.map((entry) {
      return PlaylistItem(
        mediaFile: entry.value,
        dateAdded: DateTime.now(),
        position: entry.key,
      );
    }).toList();
  }

  List<PlaylistItem> _reindexPlaylistItems(List<PlaylistItem> items) {
    return items.asMap().entries.map((entry) {
      return PlaylistItem(
        mediaFile: entry.value.mediaFile,
        dateAdded: entry.value.dateAdded,
        position: entry.key,
        metadata: entry.value.metadata,
      );
    }).toList();
  }

  List<PlaylistItem> _removeDuplicateItems(List<PlaylistItem> items) {
    final seenPaths = <String>{};
    return items.where((item) {
      if (seenPaths.contains(item.mediaFile.path)) {
        return false;
      }
      seenPaths.add(item.mediaFile.path);
      return true;
    }).toList();
  }

  bool _itemExists(List<PlaylistItem> items, String path) {
    return items.any((item) => item.mediaFile.path == path);
  }

  bool _areItemListsEqual(List<PlaylistItem> list1, List<PlaylistItem> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].mediaFile.path != list2[i].mediaFile.path) return false;
    }

    return true;
  }

  List<MediaFile> _sortMediaFiles(
    List<MediaFile> files,
    PlaylistSortBy sortBy,
    SortOrder sortOrder,
  ) {
    final sorted = List<MediaFile>.from(files);

    sorted.sort((a, b) {
      final comparison = switch (sortBy) {
        PlaylistSortBy.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        PlaylistSortBy.dateAdded => (a.dateAdded ?? DateTime(0)).compareTo(
          b.dateAdded ?? DateTime(0),
        ),
        PlaylistSortBy.duration => (a.duration ?? Duration.zero).compareTo(
          b.duration ?? Duration.zero,
        ),
        PlaylistSortBy.fileSize => (a.size ?? 0).compareTo(b.size ?? 0),
        PlaylistSortBy.lastModified =>
          (a.lastModified ?? DateTime(0)).compareTo(
            b.lastModified ?? DateTime(0),
          ),
        PlaylistSortBy.artist => _compareMetadata(a, b, 'artist'),
        PlaylistSortBy.album => _compareMetadata(a, b, 'album'),
        PlaylistSortBy.year => _compareMetadataInt(a, b, 'year'),
        PlaylistSortBy.playCount => a.playCount.compareTo(b.playCount),
        PlaylistSortBy.rating => (a.rating ?? 0).compareTo(b.rating ?? 0),
        PlaylistSortBy.custom => 0,
      };

      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  int _compareMetadata(MediaFile a, MediaFile b, String key) {
    final aValue = (a.metadata?[key] ?? '').toString().toLowerCase();
    final bValue = (b.metadata?[key] ?? '').toString().toLowerCase();
    return aValue.compareTo(bValue);
  }

  int _compareMetadataInt(MediaFile a, MediaFile b, String key) {
    final aValue = a.metadata?[key] ?? 0;
    final bValue = b.metadata?[key] ?? 0;
    return aValue.compareTo(bValue);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYLIST FORMAT PARSERS
  // ═══════════════════════════════════════════════════════════════════════════

  List<String> _parseM3U(String content) {
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
  }

  List<String> _parsePLS(String content) {
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('File'))
        .map((line) {
          final parts = line.split('=');
          return parts.length == 2 ? parts[1] : '';
        })
        .where((path) => path.isNotEmpty)
        .toList();
  }

  List<String> _parseXSPF(String content) {
    final locationRegex = RegExp(r'<location>(.*?)</location>');
    final matches = locationRegex.allMatches(content);

    return matches
        .map((match) {
          var path = match.group(1) ?? '';
          if (path.startsWith('file://')) {
            path = path.substring(7);
          }
          return path;
        })
        .where((path) => path.isNotEmpty)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load playlists
      final playlistsJson = prefs.getString('vlc_playlists');
      if (playlistsJson != null) {
        final list = json.decode(playlistsJson) as List;
        _playlists = list.map((j) => Playlist.fromJson(j)).toList();
      }

      // Load play queue
      final queueJson = prefs.getString('play_queue');
      if (queueJson != null) {
        final list = json.decode(queueJson) as List;
        _playQueue = list.map((j) => MediaFile.fromJson(j)).toList();
      }

      // Load queue history
      final historyJson = prefs.getString('queue_history');
      if (historyJson != null) {
        final list = json.decode(historyJson) as List;
        _queueHistory = list.map((j) => MediaFile.fromJson(j)).toList();
      }

      // Load settings
      _currentQueueIndex = prefs.getInt('current_queue_index') ?? 0;
      _shuffle = prefs.getBool('shuffle') ?? false;
      _repeatMode = RepeatMode.values[prefs.getInt('repeat_mode') ?? 0];
      _playbackSpeed = prefs.getDouble('playback_speed') ?? 1.0;
      _autoPlayNext = prefs.getBool('auto_play_next') ?? true;
      _crossfade = prefs.getBool('crossfade') ?? false;
      _crossfadeDuration = prefs.getInt('crossfade_duration') ?? 3;
      _playbackOrder =
          PlaybackOrder.values[prefs.getInt('playback_order') ?? 0];
    } catch (e) {
      debugPrint('Error loading from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save playlists
      await prefs.setString(
        'vlc_playlists',
        json.encode(_playlists.map((p) => p.toJson()).toList()),
      );

      // Save play queue
      await prefs.setString(
        'play_queue',
        json.encode(_playQueue.map((m) => m.toJson()).toList()),
      );

      // Save queue history
      await prefs.setString(
        'queue_history',
        json.encode(_queueHistory.map((m) => m.toJson()).toList()),
      );

      // Save settings
      await prefs.setInt('current_queue_index', _currentQueueIndex);
      await prefs.setBool('shuffle', _shuffle);
      await prefs.setInt('repeat_mode', _repeatMode.index);
      await prefs.setDouble('playback_speed', _playbackSpeed);
      await prefs.setBool('auto_play_next', _autoPlayNext);
      await prefs.setBool('crossfade', _crossfade);
      await prefs.setInt('crossfade_duration', _crossfadeDuration);
      await prefs.setInt('playback_order', _playbackOrder.index);
    } catch (e) {
      debugPrint('Error saving to storage: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum RepeatMode {
  off,
  all,
  one;

  String get displayName => switch (this) {
    RepeatMode.off => 'Off',
    RepeatMode.all => 'Repeat All',
    RepeatMode.one => 'Repeat One',
  };

  IconData get icon => switch (this) {
    RepeatMode.off => Icons.repeat,
    RepeatMode.all => Icons.repeat,
    RepeatMode.one => Icons.repeat_one,
  };
}

enum PlaybackOrder {
  default_,
  random,
  reverseOrder;

  String get displayName => switch (this) {
    PlaybackOrder.default_ => 'Default',
    PlaybackOrder.random => 'Random',
    PlaybackOrder.reverseOrder => 'Reverse',
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _SystemPlaylistConfig {
  final PlaylistType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int maxItems;
  final PlaylistSortBy sortBy;
  final SortOrder sortOrder;
  final int position;

  _SystemPlaylistConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.maxItems = 1000,
    this.sortBy = PlaylistSortBy.name,
    this.sortOrder = SortOrder.ascending,
    required this.position,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════

extension PlaylistTypeExtension on PlaylistType {
  bool get isSystemPlaylist =>
      this == PlaylistType.favorites ||
      this == PlaylistType.recent ||
      this == PlaylistType.mostPlayed ||
      this == PlaylistType.neverPlayed;
}

// ═══════════════════════════════════════════════════════════════════════════
// EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

class PlaylistException implements Exception {
  final String message;

  PlaylistException(this.message);

  @override
  String toString() => 'PlaylistException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// STATISTICS CLASS
// ═══════════════════════════════════════════════════════════════════════════

class PlaylistStats {
  final int totalItems;
  final Duration totalDuration;
  final int totalSize;
  final int videoCount;
  final int audioCount;
  final DateTime createdAt;
  final DateTime lastModified;

  PlaylistStats({
    required this.totalItems,
    required this.totalDuration,
    required this.totalSize,
    required this.videoCount,
    required this.audioCount,
    required this.createdAt,
    required this.lastModified,
  });

  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    final seconds = totalDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get itemSummary {
    final parts = <String>[];
    if (videoCount > 0)
      parts.add('$videoCount video${videoCount != 1 ? 's' : ''}');
    if (audioCount > 0)
      parts.add('$audioCount audio${audioCount != 1 ? 's' : ''}');
    return parts.join(', ');
  }
}
