import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_file.dart';
import '../models/media_folder.dart';
import '../services/permission_service.dart';
import '../services/database_service.dart';

class MediaProvider extends ChangeNotifier {
  List<MediaFile> _recentFiles = [];
  List<MediaFile> _favorites = [];
  List<List<MediaFile>> _playlists = [];
  List<String> _playlistNames = [];
  List<MediaFile> _allMediaFiles = [];
  List<MediaFile> _videoFiles = [];
  List<MediaFile> _audioFiles = [];
  MediaFile? _currentMedia;
  int _currentIndex = 0;
  bool _isScanning = false;
  int _scannedFilesCount = 0;
  String _currentScanFolder = '';

  List<MediaFile> get recentFiles => _recentFiles;
  List<MediaFile> get favorites => _favorites;
  List<List<MediaFile>> get playlists => _playlists;
  List<String> get playlistNames => _playlistNames;
  List<MediaFile> get allMediaFiles => _allMediaFiles;
  List<MediaFile> get videoFiles => _videoFiles;
  List<MediaFile> get audioFiles => _audioFiles;
  MediaFile? get currentMedia => _currentMedia;
  int get currentIndex => _currentIndex;
  bool get isScanning => _isScanning;
  int get scannedFilesCount => _scannedFilesCount;
  String get currentScanFolder => _currentScanFolder;

  MediaProvider() {
    _loadData();
    _initializeMediaScanning();
  }

  Future<void> _initializeMediaScanning() async {
    final hasPermissions = await PermissionService.checkMediaPermissions();
    if (hasPermissions) {
      await _loadFromCacheOrScan();
    }
  }

  Future<void> _loadFromCacheOrScan() async {
    try {
      final cacheValid = await DatabaseService.isCacheValid();
      final shouldIncremental = await DatabaseService.shouldIncrementalScan();

      if (cacheValid) {
        _isScanning = true;
        notifyListeners();

        await _loadFromCache();

        _isScanning = false;
        notifyListeners();
      } else if (shouldIncremental) {
        _isScanning = true;
        notifyListeners();

        await _loadFromCache();
        await _performIncrementalScan();

        _isScanning = false;
        notifyListeners();
      } else {
        await scanAllMediaFiles();
      }
    } catch (e) {
      await scanAllMediaFiles();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedFolders = await DatabaseService.getCachedMediaFolders();
      final cachedFiles = await DatabaseService.getCachedMediaFiles();

      _mediaFolders = cachedFolders;
      _allMediaFiles = cachedFiles;
      _videoFiles = cachedFiles.where((media) => media.type == MediaType.video).toList();
      _audioFiles = cachedFiles.where((media) => media.type == MediaType.audio).toList();

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load from cache: $e');
    }
  }

  Future<void> _performIncrementalScan() async {
    try {
      final knownPaths = await DatabaseService.getKnownFilePaths();
      final currentFiles = <MediaFile>[];
      final currentPaths = <String>[];
      final modifiedFiles = <MediaFile>[];
      final newFiles = <MediaFile>[];

      // Quick scan of known directories to check for changes
      final foldersToCheck = _mediaFolders.map((folder) => Directory(folder.path)).toList();

      for (final folder in foldersToCheck) {
        if (await folder.exists()) {
          await for (final entity in folder.list()) {
            if (entity is File) {
              final mediaFile = MediaFile.fromFile(entity);
              if (mediaFile.type != MediaType.unknown) {
                currentFiles.add(mediaFile);
                currentPaths.add(mediaFile.path);

                if (knownPaths.contains(mediaFile.path)) {
                  // Check if file was modified
                  final cachedFile = _allMediaFiles.firstWhere(
                    (f) => f.path == mediaFile.path,
                    orElse: () => mediaFile,
                  );
                  if (cachedFile.lastModified != mediaFile.lastModified ||
                      cachedFile.size != mediaFile.size) {
                    modifiedFiles.add(mediaFile);
                  }
                } else {
                  newFiles.add(mediaFile);
                }
              }
            }
          }
        }
      }

      // Update database with changes
      if (newFiles.isNotEmpty) {
        await DatabaseService.cacheMediaFiles(newFiles);
      }
      if (modifiedFiles.isNotEmpty) {
        await DatabaseService.updateModifiedFiles(modifiedFiles);
      }
      await DatabaseService.removeDeletedFiles(currentPaths);

      // Update local lists if there were changes
      if (newFiles.isNotEmpty || modifiedFiles.isNotEmpty ||
          currentPaths.length != knownPaths.length) {
        await _loadFromCache();

        // Record incremental scan
        await DatabaseService.recordScanHistory(
          currentFiles.length,
          foldersToCheck.length,
          0, // Quick scan
        );
      }
    } catch (e) {
      print('Incremental scan failed: $e');
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load recent files
    final recentPaths = prefs.getStringList('recent_files') ?? [];
    _recentFiles = recentPaths
        .map((path) => File(path))
        .where((file) => file.existsSync())
        .map((file) => MediaFile.fromFile(file))
        .toList();

    // Load favorites
    final favoritePaths = prefs.getStringList('favorite_files') ?? [];
    _favorites = favoritePaths
        .map((path) => File(path))
        .where((file) => file.existsSync())
        .map((file) => MediaFile.fromFile(file))
        .toList();

    // Load playlists
    _playlistNames = prefs.getStringList('playlist_names') ?? [];
    _playlists = [];
    for (int i = 0; i < _playlistNames.length; i++) {
      final playlistPaths = prefs.getStringList('playlist_$i') ?? [];
      final playlist = playlistPaths
          .map((path) => File(path))
          .where((file) => file.existsSync())
          .map((file) => MediaFile.fromFile(file))
          .toList();
      _playlists.add(playlist);
    }

    notifyListeners();
  }

  Future<void> addToRecent(MediaFile media) async {
    _recentFiles.removeWhere((file) => file.path == media.path);
    _recentFiles.insert(0, media);

    if (_recentFiles.length > 20) {
      _recentFiles = _recentFiles.take(20).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_files', _recentFiles.map((f) => f.path).toList());
    notifyListeners();
  }

  Future<void> toggleFavorite(MediaFile media) async {
    final isFavorite = _favorites.any((file) => file.path == media.path);

    if (isFavorite) {
      _favorites.removeWhere((file) => file.path == media.path);
      // Remove from Favorites playlist if it exists
      final favoritesIndex = _playlistNames.indexOf('Favorites');
      if (favoritesIndex != -1) {
        _playlists[favoritesIndex].removeWhere((file) => file.path == media.path);
      }
    } else {
      _favorites.add(media);
      // Ensure Favorites playlist exists
      await _ensureFavoritesPlaylist();
      // Add to Favorites playlist
      final favoritesIndex = _playlistNames.indexOf('Favorites');
      if (favoritesIndex != -1) {
        _playlists[favoritesIndex].add(media);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_files', _favorites.map((f) => f.path).toList());
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> _ensureFavoritesPlaylist() async {
    if (!_playlistNames.contains('Favorites')) {
      await createPlaylist('Favorites');
    }
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('playlist_names', _playlistNames);

    for (int i = 0; i < _playlists.length; i++) {
      await prefs.setStringList(
        'playlist_$i',
        _playlists[i].map((f) => f.path).toList(),
      );
    }
  }

  bool isFavorite(MediaFile media) {
    return _favorites.any((file) => file.path == media.path);
  }

  Future<void> createPlaylist(String name) async {
    if (_playlistNames.contains(name)) return;

    _playlistNames.add(name);
    _playlists.add([]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('playlist_names', _playlistNames);
    notifyListeners();
  }

  Future<void> addToPlaylist(int playlistIndex, MediaFile media) async {
    if (playlistIndex >= _playlists.length) return;

    final playlist = _playlists[playlistIndex];
    if (!playlist.any((file) => file.path == media.path)) {
      playlist.add(media);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'playlist_$playlistIndex',
        playlist.map((f) => f.path).toList(),
      );
      notifyListeners();
    }
  }

  Future<void> removeFromPlaylist(int playlistIndex, MediaFile media) async {
    if (playlistIndex >= _playlists.length) return;

    _playlists[playlistIndex].removeWhere((file) => file.path == media.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'playlist_$playlistIndex',
      _playlists[playlistIndex].map((f) => f.path).toList(),
    );
    notifyListeners();
  }

  Future<void> deletePlaylist(int index) async {
    if (index >= _playlistNames.length) return;

    _playlistNames.removeAt(index);
    _playlists.removeAt(index);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('playlist_names', _playlistNames);

    // Remove the deleted playlist and shift others
    for (int i = index; i < _playlists.length; i++) {
      await prefs.setStringList(
        'playlist_$i',
        _playlists[i].map((f) => f.path).toList(),
      );
    }

    await prefs.remove('playlist_${_playlists.length}');
    notifyListeners();
  }

  void setCurrentMedia(MediaFile? media, {int index = 0}) {
    _currentMedia = media;
    _currentIndex = index;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> clearRecentFiles() async {
    _recentFiles.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_files');
    notifyListeners();
  }

  List<MediaFolder> _mediaFolders = [];

  List<MediaFolder> get mediaFolders => _mediaFolders;

  Future<void> scanAllMediaFiles() async {
    final scanStartTime = DateTime.now();
    _isScanning = true;
    _scannedFilesCount = 0;
    _currentScanFolder = 'Initializing...';
    notifyListeners();

    try {
      final allMedia = <MediaFile>[];
      final scannedPaths = <String>{};
      final folderMediaMap = <String, List<MediaFile>>{};

      if (Platform.isAndroid) {
        // Prioritize common media folders for faster results
        final storagePaths = [
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/storage/emulated/0/Audio',
          '/storage/emulated/0/Video',
          '/storage/emulated/0/Documents',
          '/sdcard/DCIM',
          '/sdcard/Pictures',
          '/sdcard/Movies',
          '/sdcard/Music',
        ];

        for (String path in storagePaths) {
          try {
            final dir = Directory(path);
            if (await dir.exists() && !scannedPaths.contains(path)) {
              scannedPaths.add(path);
              _currentScanFolder = path.split('/').last;
              notifyListeners();
              await _scanDirectoryForFolders(dir, folderMediaMap, maxDepth: 4);
            }
          } catch (e) {
            continue;
          }
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
        final windowsPaths = [
          '$userProfile\\Videos',
          '$userProfile\\Music',
          '$userProfile\\Downloads',
          '$userProfile\\Pictures',
          '$userProfile\\Documents',
          '$userProfile\\Desktop',
        ];

        for (String path in windowsPaths) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              _currentScanFolder = path.split('\\').last;
              notifyListeners();
              await _scanDirectoryForFolders(dir, folderMediaMap, maxDepth: 3);
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Create MediaFolder objects from the grouped media files
      _mediaFolders = folderMediaMap.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) {
            final directory = Directory(entry.key);
            return MediaFolder.fromDirectory(directory, entry.value);
          })
          .toList();

      // Sort folders by total media count (descending)
      _mediaFolders.sort((a, b) => b.totalMediaCount.compareTo(a.totalMediaCount));

      // Still maintain the flat lists for backward compatibility
      for (var mediaList in folderMediaMap.values) {
        allMedia.addAll(mediaList);
      }

      _allMediaFiles = allMedia;
      _videoFiles = allMedia.where((media) => media.type == MediaType.video).toList();
      _audioFiles = allMedia.where((media) => media.type == MediaType.audio).toList();

      // Cache the results
      await _cacheResults(allMedia, _mediaFolders, scanStartTime);

      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _cacheResults(List<MediaFile> mediaFiles, List<MediaFolder> mediaFolders, DateTime scanStartTime) async {
    try {
      await DatabaseService.clearCache();
      await DatabaseService.cacheMediaFiles(mediaFiles);
      await DatabaseService.cacheMediaFolders(mediaFolders);

      final scanDuration = DateTime.now().difference(scanStartTime);
      await DatabaseService.recordScanHistory(
        mediaFiles.length,
        mediaFolders.length,
        scanDuration.inMilliseconds,
      );
    } catch (e) {
      print('Error caching results: $e');
    }
  }

  Future<void> _scanDirectoryForFolders(Directory directory, Map<String, List<MediaFile>> folderMediaMap, {int maxDepth = 2, int currentDepth = 0}) async {
    if (currentDepth >= maxDepth) return;

    try {
      // Skip hidden and system folders
      final dirName = directory.path.split(Platform.isWindows ? '\\' : '/').last;
      if (_shouldSkipFolder(dirName)) return;

      var fileCount = 0;
      await for (final entity in directory.list()) {
        try {
          if (entity is File) {
            final mediaFile = MediaFile.fromFile(entity);
            if (mediaFile.type != MediaType.unknown) {
              final folderPath = directory.path;
              if (!folderMediaMap.containsKey(folderPath)) {
                folderMediaMap[folderPath] = [];
              }
              folderMediaMap[folderPath]!.add(mediaFile);

              _scannedFilesCount++;
              fileCount++;

              // Update UI every 10 files for better performance
              if (fileCount % 10 == 0) {
                notifyListeners();
              }
            }
          } else if (entity is Directory && currentDepth < maxDepth - 1) {
            await _scanDirectoryForFolders(entity, folderMediaMap, maxDepth: maxDepth, currentDepth: currentDepth + 1);
          }
        } catch (e) {
          continue;
        }
      }

      // Final update for this folder
      if (fileCount > 0) {
        notifyListeners();
      }
    } catch (e) {
      return;
    }
  }

  bool _shouldSkipFolder(String folderName) {
    // Skip hidden folders (starting with .)
    if (folderName.startsWith('.')) return true;

    // Skip system/cache folders
    final skipFolders = [
      'Android',
      'android',
      'cache',
      'Cache',
      'temp',
      'Temp',
      'tmp',
      'thumbnails',
      'Thumbnails',
      '.trash',
      'Trash',
      'lost+found',
      'System Volume Information',
      '\$RECYCLE.BIN',
      'node_modules',
      'build',
      'dist',
    ];

    return skipFolders.contains(folderName);
  }

  Future<void> _scanDirectoryRecursively(Directory directory, List<MediaFile> mediaFiles, {int maxDepth = 2, int currentDepth = 0}) async {
    if (currentDepth >= maxDepth) return;

    try {
      await for (final entity in directory.list()) {
        try {
          if (entity is File) {
            final mediaFile = MediaFile.fromFile(entity);
            if (mediaFile.type != MediaType.unknown) {
              mediaFiles.add(mediaFile);
            }
          } else if (entity is Directory && currentDepth < maxDepth - 1) {
            await _scanDirectoryRecursively(entity, mediaFiles, maxDepth: maxDepth, currentDepth: currentDepth + 1);
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      return;
    }
  }

  void updateMediaFiles() {
    _videoFiles = _allMediaFiles.where((media) => media.type == MediaType.video).toList();
    _audioFiles = _allMediaFiles.where((media) => media.type == MediaType.audio).toList();
    notifyListeners();
  }

  Future<void> refreshMediaFiles() async {
    await scanAllMediaFiles();
  }

  Future<void> clearMediaCache() async {
    try {
      await DatabaseService.clearCache();
      _mediaFolders.clear();
      _allMediaFiles.clear();
      _videoFiles.clear();
      _audioFiles.clear();
      notifyListeners();
      await scanAllMediaFiles();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> forceRefreshCache() async {
    try {
      _isScanning = true;
      notifyListeners();

      await DatabaseService.clearCache();
      await scanAllMediaFiles();
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      print('Error force refreshing cache: $e');
    }
  }

  Future<void> quickRefresh() async {
    try {
      final shouldIncremental = await DatabaseService.shouldIncrementalScan();

      if (shouldIncremental || _allMediaFiles.isNotEmpty) {
        _isScanning = true;
        notifyListeners();

        await _performIncrementalScan();

        _isScanning = false;
        notifyListeners();
      } else {
        await forceRefreshCache();
      }
    } catch (e) {
      await forceRefreshCache();
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return await DatabaseService.getCacheStats();
  }
}