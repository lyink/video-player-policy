import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/media_file.dart';
import '../providers/media_provider.dart';
import '../services/permission_service.dart';
import '../services/admob_service.dart';
import '../widgets/media_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';
import 'video_player_screen.dart';

class FileBrowserScreen extends StatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  Directory? _currentDirectory;
  List<FileSystemEntity> _entities = [];
  List<MediaFile> _mediaFiles = [];
  List<MediaFile> _allMediaFiles = [];
  bool _isLoading = true;
  bool _isScanning = false;
  String _sortBy = 'name'; // name, date, size, type
  String _currentView = 'all_media'; // browse, all_media, quick_access
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInit();
    _loadBannerAd();
  }

  Future<void> _requestPermissionsAndInit() async {
    final hasPermissions = await PermissionService.checkMediaPermissions();
    if (!hasPermissions) {
      final granted = await PermissionService.requestMediaPermissions();
      if (!granted) {
        setState(() {
          _isLoading = false;
        });
        _showPermissionDeniedDialog();
        return;
      }
    }

    await _initializeDirectory();
    _scanAllMediaFiles();
  }

  void _loadBannerAd() {
    _bannerAd = AdMobService.createBannerAd()
      ..load().then((_) {
        if (mounted) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        }
      }).catchError((error) {
        print('Failed to load banner ad: $error');
      });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.security, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Permissions Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Media access permissions are required to browse files.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Grant permissions to access your videos and audio files',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.openSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeDirectory() async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isWindows) {
        directory = Directory(Platform.environment['USERPROFILE'] ?? 'C:\\');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null && await directory.exists()) {
        await _navigateToDirectory(directory);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAllMediaFiles() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final allMedia = <MediaFile>[];
      final scannedPaths = <String>{};

      if (Platform.isAndroid) {
        final storagePaths = [
          '/storage/emulated/0',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Audio',
          '/storage/emulated/0/Video',
          '/storage/emulated/0/Documents',
          '/sdcard',
          '/sdcard/Download',
          '/sdcard/Downloads',
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
              await _scanDirectoryRecursively(dir, allMedia, maxDepth: 3);
            }
          } catch (e) {
            continue;
          }
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
        final windowsPaths = [
          '$userProfile\\Downloads',
          '$userProfile\\Videos',
          '$userProfile\\Music',
          '$userProfile\\Pictures',
          '$userProfile\\Documents',
          '$userProfile\\Desktop',
        ];

        for (String path in windowsPaths) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              await _scanDirectoryRecursively(dir, allMedia, maxDepth: 2);
            }
          } catch (e) {
            continue;
          }
        }
      }

      setState(() {
        _allMediaFiles = allMedia;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
    }
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

  Future<void> _navigateToDirectory(Directory directory) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entities = await directory.list().toList();
      final mediaFiles = <MediaFile>[];

      for (final entity in entities) {
        if (entity is File) {
          final mediaFile = MediaFile.fromFile(entity);
          if (mediaFile.type != MediaType.unknown) {
            mediaFiles.add(mediaFile);
          }
        }
      }

      setState(() {
        _currentDirectory = directory;
        _entities = entities;
        _mediaFiles = mediaFiles;
        _isLoading = false;
      });

      _sortFiles();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortFiles() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _mediaFiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          _entities.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
          break;
        case 'date':
          _mediaFiles.sort((a, b) {
            final aDate = a.lastModified ?? DateTime(0);
            final bDate = b.lastModified ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          _entities.sort((a, b) {
            final aStat = a.statSync();
            final bStat = b.statSync();
            return bStat.modified.compareTo(aStat.modified);
          });
          break;
        case 'size':
          _mediaFiles.sort((a, b) {
            final aSize = a.size ?? 0;
            final bSize = b.size ?? 0;
            return bSize.compareTo(aSize);
          });
          break;
        case 'type':
          _mediaFiles.sort((a, b) {
            if (a.type != b.type) {
              return a.type.index.compareTo(b.type.index);
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          break;
      }
    });
  }

  Future<void> _navigateUp() async {
    if (_currentDirectory?.parent != null) {
      await _navigateToDirectory(_currentDirectory!.parent);
    }
  }

  void _openMedia(MediaFile media) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    mediaProvider.addToRecent(media);
    mediaProvider.setCurrentMedia(media);

    // Show interstitial ad before opening media with delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (AdMobService.isInterstitialAdAvailable) {
        AdMobService.showInterstitialAd();
      }
    });

    if (media.type == MediaType.video) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(media: media),
        ),
      );
    } else if (media.type == MediaType.audio) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(media: media),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          if (_currentView != 'quick_access')
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
                _sortFiles();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, color: _sortBy == 'name' ? Theme.of(context).primaryColor : null),
                      const SizedBox(width: 8),
                      const Text('Sort by Name'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: _sortBy == 'date' ? Theme.of(context).primaryColor : null),
                      const SizedBox(width: 8),
                      const Text('Sort by Date'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'size',
                  child: Row(
                    children: [
                      Icon(Icons.storage, color: _sortBy == 'size' ? Theme.of(context).primaryColor : null),
                      const SizedBox(width: 8),
                      const Text('Sort by Size'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'type',
                  child: Row(
                    children: [
                      Icon(Icons.category, color: _sortBy == 'type' ? Theme.of(context).primaryColor : null),
                      const SizedBox(width: 8),
                      const Text('Sort by Type'),
                    ],
                  ),
                ),
              ],
            ),
          if (_currentView == 'browse' && _currentDirectory?.parent != null)
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _navigateUp,
              tooltip: 'Go up one level',
            ),
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner ad at top
          const BannerAdWidget(showAlways: true),
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(),
        onTap: _onBottomNavTap,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.library_music),
                if (_allMediaFiles.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '${_allMediaFiles.length}',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'All Media',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Quick Access',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentView) {
      case 'all_media':
        return 'All Media Files (${_allMediaFiles.length})';
      case 'quick_access':
        return 'Quick Access';
      default:
        return _currentDirectory?.path.split(Platform.pathSeparator).last ?? 'File Browser';
    }
  }

  int _getCurrentIndex() {
    switch (_currentView) {
      case 'all_media':
        return 1;
      case 'quick_access':
        return 2;
      default:
        return 0;
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      switch (index) {
        case 0:
          _currentView = 'browse';
          break;
        case 1:
          _currentView = 'all_media';
          break;
        case 2:
          _currentView = 'quick_access';
          break;
      }
    });
  }

  Widget _buildContent() {
    switch (_currentView) {
      case 'all_media':
        return _buildAllMediaView();
      case 'quick_access':
        return _buildQuickAccessView();
      default:
        return _buildFileList();
    }
  }

  Widget _buildAllMediaView() {
    if (_allMediaFiles.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isScanning
                        ? [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)]
                        : [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: _isScanning
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Icon(
                        Icons.search_off,
                        size: 60,
                        color: Colors.grey[400],
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                _isScanning ? 'Scanning for media files...' : 'No media files found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isScanning
                    ? 'Please wait while we search your device for videos and audio files'
                    : 'Try checking permissions or scanning manually',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (!_isScanning) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _scanAllMediaFiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final sortedMedia = List<MediaFile>.from(_allMediaFiles);
    _sortMediaFiles(sortedMedia);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.library_music, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media Library',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${sortedMedia.length} files found',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isScanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedMedia.length,
            itemBuilder: (context, index) {
              final media = sortedMedia[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: MediaCard(
                  media: media,
                  onTap: () => _openMedia(media),
                  showDetails: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessView() {
    final quickAccessDirs = QuickAccessDirectory.getQuickAccessDirectories();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quickAccessDirs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Quick Access Folders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final quickDir = quickAccessDirs[index - 1];
        final fullPath = Platform.isWindows
            ? '${Platform.environment['USERPROFILE']}\\${quickDir.path}'
            : quickDir.path;

        return Card(
          child: ListTile(
            leading: Icon(quickDir.icon, color: Theme.of(context).primaryColor),
            title: Text(quickDir.name),
            subtitle: Text(fullPath),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final dir = Directory(fullPath);
              if (await dir.exists()) {
                setState(() {
                  _currentView = 'browse';
                });
                await _navigateToDirectory(dir);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Directory not found: ${quickDir.name}')),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFileList() {
    if (_entities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No files found in this directory'),
          ],
        ),
      );
    }

    final directories = _entities.whereType<Directory>().toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: directories.length + _mediaFiles.length + 1, // +1 for media files header
      itemBuilder: (context, index) {
        // Directories section
        if (index < directories.length) {
          final directory = directories[index];
          final name = directory.path.split(Platform.pathSeparator).last;

          return Card(
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(name),
              subtitle: const Text('Folder'),
              onTap: () => _navigateToDirectory(directory),
            ),
          );
        }

        // Media files header
        if (index == directories.length) {
          if (_mediaFiles.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(Icons.library_music, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Media Files (${_mediaFiles.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        // Media files
        final mediaIndex = index - directories.length - 1;
        if (mediaIndex < _mediaFiles.length) {
          final media = _mediaFiles[mediaIndex];
          return MediaCard(
            media: media,
            onTap: () => _openMedia(media),
            showDetails: true,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _sortMediaFiles(List<MediaFile> mediaFiles) {
    switch (_sortBy) {
      case 'name':
        mediaFiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'date':
        mediaFiles.sort((a, b) {
          final aDate = a.lastModified ?? DateTime(0);
          final bDate = b.lastModified ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
        break;
      case 'size':
        mediaFiles.sort((a, b) {
          final aSize = a.size ?? 0;
          final bSize = b.size ?? 0;
          return bSize.compareTo(aSize);
        });
        break;
      case 'type':
        mediaFiles.sort((a, b) {
          if (a.type != b.type) {
            return a.type.index.compareTo(b.type.index);
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }
  }
}

// Common storage locations for quick access
class QuickAccessDirectory {
  final String name;
  final String path;
  final IconData icon;

  const QuickAccessDirectory({
    required this.name,
    required this.path,
    required this.icon,
  });

  static List<QuickAccessDirectory> getQuickAccessDirectories() {
    if (Platform.isWindows) {
      return [
        const QuickAccessDirectory(
          name: 'Desktop',
          path: 'Desktop',
          icon: Icons.desktop_windows,
        ),
        const QuickAccessDirectory(
          name: 'Downloads',
          path: 'Downloads',
          icon: Icons.download,
        ),
        const QuickAccessDirectory(
          name: 'Videos',
          path: 'Videos',
          icon: Icons.video_library,
        ),
        const QuickAccessDirectory(
          name: 'Music',
          path: 'Music',
          icon: Icons.library_music,
        ),
      ];
    } else if (Platform.isAndroid) {
      return [
        const QuickAccessDirectory(
          name: 'Downloads',
          path: '/storage/emulated/0/Download',
          icon: Icons.download,
        ),
        const QuickAccessDirectory(
          name: 'DCIM',
          path: '/storage/emulated/0/DCIM',
          icon: Icons.photo_camera,
        ),
        const QuickAccessDirectory(
          name: 'Movies',
          path: '/storage/emulated/0/Movies',
          icon: Icons.video_library,
        ),
        const QuickAccessDirectory(
          name: 'Music',
          path: '/storage/emulated/0/Music',
          icon: Icons.library_music,
        ),
      ];
    }
    return [];
  }
}