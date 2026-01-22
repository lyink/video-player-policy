import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import '../models/media_file.dart';
import '../models/media_folder.dart';
import '../widgets/media_card.dart';
import '../widgets/folder_card.dart';
import '../widgets/platform_file_picker.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';
import '../utils/theme_colors.dart';
import '../services/permission_service.dart';
import '../services/admob_service.dart';
import 'video_player_screen.dart';
import 'file_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  bool _showFolders = true;
  MediaFolder? _selectedFolder;

  late AnimationController _searchAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _fabAnimation;

  int _selectedViewMode = 0; // 0: Folders, 1: All Files, 2: Grid View

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAndRequestPermissions();
  }

  void _setupAnimations() {
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    );

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutCubic,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!kIsWeb) {
      final hasPermissions = await PermissionService.checkMediaPermissions();
      if (!hasPermissions) {
        await PermissionService.requestMediaPermissions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MediaProvider, ThemeProvider>(
      builder: (context, mediaProvider, themeProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Animated background
              _buildAnimatedBackground(),
              // Main content
              Column(
                children: [
                  // Premium Search Bar
                  _buildPremiumSearchBar(mediaProvider),
                  // Content
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Stats Header
                        if (!_showSearch && _selectedFolder == null)
                          _buildStatsHeader(mediaProvider),

                        // View Mode Selector
                        if (!_showSearch && _selectedFolder == null)
                          _buildViewModeSelector(),

                        // Empty State
                        if (mediaProvider.mediaFolders.isEmpty &&
                            mediaProvider.videoFiles.isEmpty &&
                            mediaProvider.audioFiles.isEmpty &&
                            !mediaProvider.isScanning)
                          SliverFillRemaining(
                            child: _buildEmptyState(context, mediaProvider),
                          )
                        // Folder View
                        else if (_showFolders && _selectedFolder == null)
                          ..._buildFolderView(mediaProvider)
                        // Selected Folder Content
                        else if (_selectedFolder != null)
                          ..._buildSelectedFolderView(mediaProvider)
                        // All Files View
                        else
                          ..._buildAllFilesView(mediaProvider, themeProvider),

                        // Bottom Padding
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ],
              ),
              // Floating Action Menu
              if (!mediaProvider.isScanning)
                _buildFloatingActionMenu(mediaProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPainter(
          color1: Theme.of(context).primaryColor.withOpacity(0.03),
          color2: Theme.of(context).primaryColor.withOpacity(0.01),
        ),
      ),
    );
  }

  Widget _buildPremiumSearchBar(MediaProvider mediaProvider) {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).cardColor.withOpacity(0.9),
                  Theme.of(context).cardColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Back button for folder view
                    if (_selectedFolder != null)
                      _buildGlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _selectedFolder = null;
                            _showFolders = true;
                          });
                        },
                      ),

                    // Search Field
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _showSearch
                            ? TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(
                                    () => _searchQuery = value.toLowerCase(),
                                  );
                                },
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search media...',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                ),
                                autofocus: true,
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedFolder != null
                                          ? Icons.folder_open_rounded
                                          : Icons.video_library_rounded,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFolder?.displayName ??
                                                'Media Library',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).textTheme.titleLarge?.color,
                                            ),
                                          ),
                                          if (_selectedFolder != null)
                                            Text(
                                              _selectedFolder!.mediaCountText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    // Search Toggle
                    _buildGlassIconButton(
                      icon: _showSearch
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        });
                      },
                    ),

                    // Options Menu
                    _buildGlassIconButton(
                      icon: Icons.tune_rounded,
                      onPressed: () => _showOptionsMenu(mediaProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(MediaProvider mediaProvider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.video_library_rounded,
                count: mediaProvider.videoFiles.length,
                label: 'Videos',
                gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.audiotrack_rounded,
                count: mediaProvider.audioFiles.length,
                label: 'Audio',
                gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.folder_rounded,
                count: mediaProvider.mediaFolders.length,
                label: 'Folders',
                gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gradient[0].withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: gradient,
                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildViewModeButton(
                      icon: Icons.folder_rounded,
                      label: 'Folders',
                      isSelected: _showFolders,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _showFolders = true;
                          _selectedFolder = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildViewModeButton(
                      icon: Icons.list_rounded,
                      label: 'All Files',
                      isSelected: !_showFolders,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _showFolders = false;
                          _selectedFolder = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFolderView(MediaProvider mediaProvider) {
    return [
      const SliverToBoxAdapter(child: BannerAdWidget(showAlways: true)),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Media Folders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      Theme.of(context).primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${mediaProvider.mediaFolders.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final folder = mediaProvider.mediaFolders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPremiumFolderCard(folder),
            );
          }, childCount: mediaProvider.mediaFolders.length),
        ),
      ),

      const SliverToBoxAdapter(child: NativeAdWidget()),
    ];
  }

  Widget _buildPremiumFolderCard(MediaFolder folder) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _selectedFolder = folder;
          _showFolders = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.movie_rounded,
                        size: 14,
                        color: const Color(0xFF667eea),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        folder.mediaCountText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectedFolderView(MediaProvider mediaProvider) {
    return [
      const SliverToBoxAdapter(child: BannerAdWidget(showAlways: true)),

      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final media = _selectedFolder!.mediaFiles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPremiumMediaCard(media),
            );
          }, childCount: _selectedFolder!.mediaFiles.length),
        ),
      ),
    ];
  }

  Widget _buildPremiumMediaCard(MediaFile media) {
    final gradients = {
      MediaType.video: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      MediaType.audio: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    };
    final gradient = gradients[media.type] ?? [Colors.grey, Colors.grey];

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openMedia(context, media);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                media.type == MediaType.video
                    ? Icons.play_circle_filled_rounded
                    : Icons.music_note_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient
                                .map((c) => c.withOpacity(0.2))
                                .toList(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          media.extension.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: gradient[0],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatFileSize(media.size),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: gradient[0], size: 28),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllFilesView(
    MediaProvider mediaProvider,
    ThemeProvider themeProvider,
  ) {
    final filteredVideos = _filterMediaFiles(mediaProvider.videoFiles);
    final filteredAudio = _filterMediaFiles(mediaProvider.audioFiles);

    return [
      const SliverToBoxAdapter(child: BannerAdWidget(showAlways: true)),

      // Videos Section
      if (filteredVideos.isNotEmpty) ...[
        _buildSectionHeader(
          icon: Icons.video_library_rounded,
          title: 'Videos',
          count: filteredVideos.length,
          totalCount: mediaProvider.videoFiles.length,
          gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          themeProvider: themeProvider,
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final media = filteredVideos[index];
              return _buildGridMediaCard(media);
            }, childCount: filteredVideos.length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: NativeAdWidget()),
      ],

      // Audio Section
      if (filteredAudio.isNotEmpty) ...[
        _buildSectionHeader(
          icon: Icons.audiotrack_rounded,
          title: 'Audio',
          count: filteredAudio.length,
          totalCount: mediaProvider.audioFiles.length,
          gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
          themeProvider: themeProvider,
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final media = filteredAudio[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPremiumMediaCard(media),
              );
            }, childCount: filteredAudio.length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],

      const SliverToBoxAdapter(child: BannerAdWidget(showAlways: true)),
    ];
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required int totalCount,
    required List<Color> gradient,
    required ThemeProvider themeProvider,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const Spacer(),
            if (_searchQuery.isNotEmpty && count != totalCount)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient.map((c) => c.withOpacity(0.2)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count of $totalCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: gradient[0],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient.map((c) => c.withOpacity(0.2)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: gradient[0],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMediaCard(MediaFile media) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openMedia(context, media);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667eea).withOpacity(0.2),
                              const Color(0xFF764ba2).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          media.extension.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionMenu(MediaProvider mediaProvider) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: ScaleTransition(
        scale: _fabAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Refresh button
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4facfe).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await mediaProvider.refreshMediaFiles();
                    if (mounted) {
                      _showStyledSnackBar('Media library refreshed!');
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MediaProvider mediaProvider) {
    if (kIsWeb) {
      return WebFilePicker(
        onFileSelected: (media) => _openMedia(context, media),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 10,
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
                  colors: mediaProvider.isScanning
                      ? [
                          const Color(0xFF667eea).withOpacity(0.3),
                          const Color(0xFF764ba2).withOpacity(0.3),
                        ]
                      : [
                          Colors.grey.withOpacity(0.2),
                          Colors.grey.withOpacity(0.1),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: mediaProvider.isScanning
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF667eea)),
                      ),
                    )
                  : Icon(
                      Icons.video_library_outlined,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
            const SizedBox(height: 32),
            Text(
              mediaProvider.isScanning ? 'Scanning Media...' : 'No Media Found',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mediaProvider.isScanning
                  ? 'Found ${mediaProvider.scannedFilesCount} files'
                  : 'Start by scanning for media files',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (mediaProvider.isScanning && mediaProvider.currentScanFolder.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Scanning: ${mediaProvider.currentScanFolder}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (!mediaProvider.isScanning) ...[
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      await mediaProvider.scanAllMediaFiles();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Scan for Media',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(MediaProvider mediaProvider) {
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
                  Theme.of(context).cardColor.withOpacity(0.95),
                  Theme.of(context).cardColor.withOpacity(0.85),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
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
                  icon: Icons.refresh_rounded,
                  title: 'Refresh Library',
                  subtitle: 'Scan for new files',
                  gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                  onTap: () async {
                    Navigator.pop(context);
                    await mediaProvider.refreshMediaFiles();
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.analytics_rounded,
                  title: 'Cache Statistics',
                  subtitle: 'View storage info',
                  gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                  onTap: () {
                    Navigator.pop(context);
                    _showCacheStatsDialog(context, mediaProvider);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Clear Cache',
                  subtitle: 'Free up space',
                  gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                  onTap: () {
                    Navigator.pop(context);
                    _showClearCacheDialog(context, mediaProvider);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.security_rounded,
                  title: 'Permissions',
                  subtitle: 'Manage access',
                  gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  onTap: () {
                    Navigator.pop(context);
                    _showPermissionDialog(context);
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
    required List<Color> gradient,
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
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<MediaFile> _filterMediaFiles(List<MediaFile> files) {
    if (_searchQuery.isEmpty) return files;
    return files.where((media) {
      return media.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _openMedia(BuildContext context, MediaFile media) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    mediaProvider.addToRecent(media);
    mediaProvider.setCurrentMedia(media);
    AdMobService.showInterstitialAdIfAvailable();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VideoPlayerScreen(media: media),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showStyledSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    // Implementation similar to original but with premium styling
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.security_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Permissions'),
          ],
        ),
        content: const Text('Permission dialog content...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(
    BuildContext context,
    MediaProvider mediaProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data and force a rescan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await mediaProvider.clearMediaCache();
              _showStyledSnackBar('Cache cleared!');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showCacheStatsDialog(
    BuildContext context,
    MediaProvider mediaProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cache Statistics'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: mediaProvider.getCacheStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final stats = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total: ${stats['totalFiles']}'),
                Text('Videos: ${stats['videoCount']}'),
                Text('Audio: ${stats['audioCount']}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  _BackgroundPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 100, paint1);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 150, paint2);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 80, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
