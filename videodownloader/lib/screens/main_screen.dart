import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/media_provider.dart';
import '../services/permission_service.dart';
import '../utils/theme_colors.dart';
import '../widgets/simple_mini_player.dart';
import '../services/simple_audio_service.dart';
import '../services/intent_service.dart';
import '../models/media_file.dart';
import '../screens/video_player_screen.dart';
import '../screens/modern_audio_player.dart';
import '../services/admob_service.dart';
import 'home_screen.dart';
import 'advanced_playlists_screen.dart';
import 'settings_screen.dart';
import 'dart:io';
import 'dart:ui';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _notificationPermissionRequested = false;
  late AnimationController _fabController;
  late AnimationController _navBarController;
  late AnimationController _drawerController;
  bool _showMiniPlayer = false;

  late final List<Widget> _screens;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.explore_rounded,
      activeIcon: Icons.explore,
      label: 'Discover',
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    _NavItem(
      icon: Icons.library_music_rounded,
      activeIcon: Icons.library_music,
      label: 'Library',
      gradient: [Color(0xFFf093fb), Color(0xFff5576c)],
    ),
    _NavItem(
      icon: Icons.settings_rounded,
      activeIcon: Icons.settings,
      label: 'Settings',
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize screens once to maintain state across tab switches
    _screens = [
      HomeScreen(key: PageStorageKey('home')),
      AdvancedPlaylistsScreen(key: PageStorageKey('playlists')),
      SettingsScreen(key: PageStorageKey('settings')),
    ];

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _navBarController.forward();
    _requestNotificationPermission();
    _setupIntentHandler();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _navBarController.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _setupIntentHandler() {
    IntentService.setIntentHandler((String filePath) {
      _handleFileOpen(filePath);
    });
  }

  void _handleFileOpen(String filePath) {
    final file = File(filePath);
    if (!file.existsSync() && !filePath.startsWith('content://')) {
      _showErrorSnackBar('File does not exist');
      return;
    }

    final fileName = filePath.split('/').last;
    final extension = fileName.toLowerCase().split('.').last;

    final audioExtensions = ['mp3', 'm4a', 'aac', 'flac', 'wav', 'ogg'];
    final videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', '3gp'];

    MediaFile? mediaFile;

    if (audioExtensions.contains(extension)) {
      mediaFile = MediaFile(
        name: fileName,
        path: filePath,
        extension: extension,
        type: MediaType.audio,
        size: filePath.startsWith('content://') ? 0 : file.lengthSync(),
        lastModified: filePath.startsWith('content://')
            ? DateTime.now()
            : file.lastModifiedSync(),
      );
    } else if (videoExtensions.contains(extension)) {
      mediaFile = MediaFile(
        name: fileName,
        path: filePath,
        extension: extension,
        type: MediaType.video,
        size: filePath.startsWith('content://') ? 0 : file.lengthSync(),
        lastModified: filePath.startsWith('content://')
            ? DateTime.now()
            : file.lastModifiedSync(),
      );
    }

    if (mediaFile != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              VideoPlayerScreen(media: mediaFile!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      _showErrorSnackBar('Unsupported file type: $extension');
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_notificationPermissionRequested) return;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final hasPermission = await PermissionService.checkNotificationPermission();
    if (!hasPermission) {
      _showNotificationPermissionDialog();
    }

    setState(() => _notificationPermissionRequested = true);
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.95),
                  Theme.of(context).primaryColor.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Icon
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
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
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Stay in the Loop!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Get instant updates on new features, media imports, and personalized recommendations.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Benefits
                      _buildBenefitRow(
                        icon: Icons.flash_on_rounded,
                        text: 'Instant notifications',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitRow(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Smart recommendations',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitRow(
                        icon: Icons.sync_rounded,
                        text: 'Real-time sync updates',
                      ),
                      const SizedBox(height: 32),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: _GlassButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Later',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _PremiumButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final granted =
                                    await PermissionService.requestNotificationPermission();
                                if (mounted) {
                                  _showCustomSnackBar(
                                    granted
                                        ? '🎉 Notifications enabled!'
                                        : '📱 Enable anytime in settings',
                                    isSuccess: granted,
                                  );
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Enable',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, MediaProvider>(
      builder: (context, themeProvider, mediaProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: _buildModernAppBar(themeProvider, mediaProvider),
          body: Stack(
            children: [
              // Animated Background
              _buildAnimatedBackground(),
              // Content
              SafeArea(
                bottom: false,
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
              // Mini Player
              Positioned(
                left: 16,
                right: 16,
                bottom: 100,
                child: Consumer<SimpleAudioService>(
                  builder: (context, audioService, child) {
                    if (!audioService.hasMedia) {
                      return const SizedBox.shrink();
                    }

                    return TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _ModernMiniPlayer(
                              currentMedia: audioService.currentMedia!,
                              isPlaying: audioService.isPlaying,
                              onPlayPause: audioService.togglePlayPause,
                              onNext: audioService.canSkipNext
                                  ? audioService.skipNext
                                  : null,
                              onPrevious: audioService.canSkipPrevious
                                  ? audioService.skipPrevious
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildModernBottomNav(themeProvider),
          floatingActionButton: _buildFloatingActionButton(mediaProvider),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  PreferredSizeWidget _buildModernAppBar(
    ThemeProvider themeProvider,
    MediaProvider mediaProvider,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Theme.of(context).brightness,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: _buildGlassIconButton(
        icon: Icons.menu_rounded,
        onPressed: _showPremiumDrawer,
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ).createShader(bounds),
        child: const Text(
          'MediaFlow',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        if (mediaProvider.isScanning)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        _buildGlassIconButton(
          icon: themeProvider.themeIcon,
          onPressed: themeProvider.cycleTheme,
          tooltip: themeProvider.themeName,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 20),
      builder: (context, double value, child) {
        return CustomPaint(
          painter: _BackgroundPainter(
            color1: Theme.of(context).primaryColor.withOpacity(0.05),
            color2: Theme.of(context).primaryColor.withOpacity(0.02),
            animationValue: value,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildModernBottomNav(ThemeProvider themeProvider) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _navBarController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
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
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _navItems.length,
                  (index) => _buildNavItem(index, themeProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeProvider themeProvider) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          // Show interstitial ad when switching tabs
          if (_currentIndex != index) {
            AdMobService.showInterstitialAdIfAvailable();
          }
          setState(() => _currentIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 20 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: item.gradient)
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: item.gradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                  size: 24,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget? _buildFloatingActionButton(MediaProvider mediaProvider) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _navBarController,
        curve: Curves.elasticOut,
      ),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
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
              _showCustomSnackBar('Media library refreshed!', isSuccess: true);
            },
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _showPremiumDrawer() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PremiumDrawer(
        onRefresh: () async {
          Navigator.pop(context);
          final mediaProvider = Provider.of<MediaProvider>(
            context,
            listen: false,
          );
          await mediaProvider.refreshMediaFiles();
          _showCustomSnackBar('Media refreshed!', isSuccess: true);
        },
        onCacheInfo: () {
          Navigator.pop(context);
          _showCacheStatsDialog();
        },
        onNavigate: (int index) {
          Navigator.pop(context);
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _showCacheStatsDialog() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).cardColor.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.2),
                              Theme.of(context).primaryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.storage_rounded,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Cache Statistics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats
                      FutureBuilder<Map<String, dynamic>>(
                        future: mediaProvider.getCacheStats(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          final stats = snapshot.data!;
                          final lastScanTime =
                              stats['lastScanTime'] as DateTime?;

                          return Column(
                            children: [
                              _buildStatCard(
                                icon: Icons.video_library_rounded,
                                label: 'Video Files',
                                value: '${stats['videoCount']}',
                                gradient: [
                                  Color(0xFF667eea),
                                  Color(0xFF764ba2),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                icon: Icons.audiotrack_rounded,
                                label: 'Audio Files',
                                value: '${stats['audioCount']}',
                                gradient: [
                                  Color(0xFFf093fb),
                                  Color(0xFFf5576c),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                icon: Icons.folder_rounded,
                                label: 'Folders',
                                value: '${stats['totalFolders']}',
                                gradient: [
                                  Color(0xFF4facfe),
                                  Color(0xFF00f2fe),
                                ],
                              ),
                              if (lastScanTime != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Last scan: ${_formatDateTime(lastScanTime)}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: _GlassButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PremiumButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await mediaProvider.quickRefresh();
                                _showCustomSnackBar(
                                  'Cache refreshed!',
                                  isSuccess: true,
                                );
                              },
                              child: const Text(
                                'Refresh',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradient[0].withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: gradient,
                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCustomSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
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
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showCustomSnackBar(message, isSuccess: false);
  }
}

// Custom Widgets
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final List<Color> gradient;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
  });
}

class _ModernMiniPlayer extends StatelessWidget {
  final MediaFile currentMedia;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const _ModernMiniPlayer({
    required this.currentMedia,
    required this.isPlaying,
    required this.onPlayPause,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
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
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Album Art
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      currentMedia.type == MediaType.audio
                          ? Icons.music_note_rounded
                          : Icons.movie_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentMedia.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentMedia.extension.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onPrevious != null)
                        _MiniPlayerButton(
                          icon: Icons.skip_previous_rounded,
                          onPressed: onPrevious!,
                        ),
                      const SizedBox(width: 8),
                      _MiniPlayerButton(
                        icon: isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onPressed: onPlayPause,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 8),
                      if (onNext != null)
                        _MiniPlayerButton(
                          icon: Icons.skip_next_rounded,
                          onPressed: onNext!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MiniPlayerButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isPrimary ? 48 : 40,
      height: isPrimary ? 48 : 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              )
            : null,
        color: isPrimary ? null : Colors.white.withOpacity(0.1),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : Theme.of(context).iconTheme.color,
            size: isPrimary ? 28 : 22,
          ),
        ),
      ),
    );
  }
}

class _PremiumDrawer extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onCacheInfo;
  final Function(int) onNavigate;

  const _PremiumDrawer({
    required this.onRefresh,
    required this.onCacheInfo,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 24),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Profile Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Container(
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
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'MediaFlow Pro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatPill(
                            icon: Icons.video_library_rounded,
                            count: mediaProvider.videoFiles.length,
                            label: 'Videos',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatPill(
                            icon: Icons.audiotrack_rounded,
                            count: mediaProvider.audioFiles.length,
                            label: 'Audio',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Actions
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _DrawerActionTile(
                            icon: Icons.refresh_rounded,
                            title: 'Refresh Library',
                            subtitle: 'Scan for new media files',
                            onTap: onRefresh,
                          ),
                          const SizedBox(height: 16),
                          _DrawerActionTile(
                            icon: Icons.favorite_rounded,
                            title: 'Favorites',
                            subtitle: 'View your favorite media',
                            onTap: () => onNavigate(1), // Navigate to Library/Playlists tab
                          ),
                          const SizedBox(height: 16),
                          _DrawerActionTile(
                            icon: Icons.playlist_play_rounded,
                            title: 'Playlists',
                            subtitle: 'Manage your playlists',
                            onTap: () => onNavigate(1), // Navigate to Library/Playlists tab
                          ),
                          const SizedBox(height: 16),
                          _DrawerActionTile(
                            icon: Icons.history_rounded,
                            title: 'Recent Played',
                            subtitle: 'View recently played media',
                            onTap: () => onNavigate(0), // Navigate to Home tab
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅 Good morning!';
    if (hour < 17) return '☀️ Good afternoon!';
    if (hour < 21) return '🌆 Good evening!';
    return '🌙 Good night!';
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
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
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _GlassButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _PremiumButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double animationValue;

  _BackgroundPainter({
    required this.color1,
    required this.color2,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    // Animated circles
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3 * animationValue),
      100,
      paint1,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7 * (1 - animationValue)),
      150,
      paint2,
    );

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 80, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
