import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:ui';
import '../providers/theme_provider.dart';
import '../providers/media_provider.dart';
import '../providers/settings_provider.dart';
import '../services/admob_service.dart';
import '../utils/theme_colors.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium Header
                _buildPremiumHeader(),

                // Theme Section
                _buildThemeSection(),

                // Playback Section
                _buildPlaybackSection(),

                const SliverToBoxAdapter(child: NativeAdWidget()),

                // Video Section
                _buildVideoSection(),

                // Audio Section
                _buildAudioSection(),

                const SliverToBoxAdapter(
                  child: BannerAdWidget(showAlways: true),
                ),

                // Library Section
                _buildLibrarySection(),

                // Premium Features
                _buildPremiumFeaturesSection(),

                const SliverToBoxAdapter(child: NativeAdWidget()),

                // About Section
                _buildAboutSection(),

                // Bottom Padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildPremiumHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Customize your experience',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.palette_rounded,
              title: 'Appearance',
              gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildGlassCard(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: AppTheme.values.map((theme) {
                            final isSelected =
                                themeProvider.currentTheme == theme;
                            return _buildThemeCard(
                              theme,
                              isSelected,
                              themeProvider,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    AppTheme theme,
    bool isSelected,
    ThemeProvider provider,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        provider.setTheme(theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: _getThemeGradient(theme),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getThemeIcon(theme),
              color: theme == AppTheme.light ? Colors.black : Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _getThemeName(theme),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: theme == AppTheme.light ? Colors.black : Colors.white,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme == AppTheme.light ? Colors.black : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.play_circle_rounded,
              title: 'Playback',
              gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
            ),
            const SizedBox(height: 16),
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return _buildGlassCard(
                  child: Column(
                    children: [
                      _buildPremiumToggleTile(
                        icon: Icons.replay_rounded,
                        title: 'Auto-repeat',
                        subtitle: 'Loop media when finished',
                        value: settingsProvider.autoRepeat,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          settingsProvider.setAutoRepeat(value);
                        },
                        gradient: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                      ),
                      _buildDivider(),
                      _buildPremiumToggleTile(
                        icon: Icons.skip_next_rounded,
                        title: 'Auto-play next',
                        subtitle: 'Continue to next in playlist',
                        value: settingsProvider.autoPlayNext,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          settingsProvider.setAutoPlayNext(value);
                        },
                        gradient: [
                          const Color(0xFFf093fb),
                          const Color(0xFFf5576c),
                        ],
                      ),
                      _buildDivider(),
                      _buildPremiumToggleTile(
                        icon: Icons.volume_up_rounded,
                        title: 'Volume boost',
                        subtitle: 'Enhance audio volume',
                        value: settingsProvider.volumeBoost,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          settingsProvider.setVolumeBoost(value);
                        },
                        gradient: [
                          const Color(0xFF4facfe),
                          const Color(0xFF00f2fe),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.video_library_rounded,
              title: 'Video',
              gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
            ),
            const SizedBox(height: 16),
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return _buildGlassCard(
                  child: Column(
                    children: [
                      _buildPremiumListTile(
                        icon: Icons.aspect_ratio_rounded,
                        title: 'Aspect ratio',
                        subtitle: settingsProvider.aspectRatio,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showAspectRatioDialog(context);
                        },
                        gradient: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                      ),
                      _buildDivider(),
                      _buildPremiumToggleTile(
                        icon: Icons.high_quality_rounded,
                        title: 'Hardware acceleration',
                        subtitle: 'Use GPU decoding',
                        value: settingsProvider.hardwareAcceleration,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          settingsProvider.setHardwareAcceleration(value);
                        },
                        gradient: [
                          const Color(0xFFf093fb),
                          const Color(0xFFf5576c),
                        ],
                      ),
                      _buildDivider(),
                      _buildPremiumListTile(
                        icon: Icons.subtitles_rounded,
                        title: 'Subtitle settings',
                        subtitle: 'Configure appearance',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showSubtitleSettings(context);
                        },
                        gradient: [
                          const Color(0xFF4facfe),
                          const Color(0xFF00f2fe),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.audiotrack_rounded,
              title: 'Audio',
              gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
            ),
            const SizedBox(height: 16),
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return _buildGlassCard(
                  child: Column(
                    children: [
                      _buildPremiumListTile(
                        icon: Icons.equalizer_rounded,
                        title: 'Equalizer',
                        subtitle: 'Adjust frequencies',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showEqualizerSettings(context);
                        },
                        gradient: [
                          const Color(0xFFf093fb),
                          const Color(0xFFf5576c),
                        ],
                      ),
                      _buildDivider(),
                      _buildPremiumListTile(
                        icon: Icons.speaker_rounded,
                        title: 'Audio output',
                        subtitle: settingsProvider.audioOutput,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showAudioOutputDialog(context);
                        },
                        gradient: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarySection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.folder_rounded,
              title: 'Library',
              gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
            ),
            const SizedBox(height: 16),
            Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                return _buildGlassCard(
                  child: Column(
                    children: [
                      _buildPremiumListTile(
                        icon: Icons.history_rounded,
                        title: 'Clear recent files',
                        subtitle:
                            '${mediaProvider.recentFiles.length} recent files',
                        onTap: mediaProvider.recentFiles.isEmpty
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                _showClearRecentDialog(context, mediaProvider);
                              },
                        gradient: [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFFF8E53),
                        ],
                      ),
                      _buildDivider(),
                      _buildPremiumListTile(
                        icon: Icons.folder_open_rounded,
                        title: 'Default folder',
                        subtitle: 'Set default location',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showDefaultFolderDialog(context);
                        },
                        gradient: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                      ),
                      _buildDivider(),
                      _buildPremiumListTile(
                        icon: Icons.refresh_rounded,
                        title: 'Scan for media',
                        subtitle: 'Search for new files',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _scanForMedia(context);
                        },
                        gradient: [
                          const Color(0xFF4facfe),
                          const Color(0xFF00f2fe),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeaturesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.star_rounded,
              title: 'Premium Features',
              gradient: [const Color(0xFFFFD700), const Color(0xFFFFB800)],
            ),
            const SizedBox(height: 16),
            _buildGlassCard(
              child: Column(
                children: [
                  _buildPremiumFeatureTile(
                    icon: Icons.star_rounded,
                    title: 'Remove Ads (24h)',
                    subtitle: 'Watch ad for ad-free experience',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showRewardedAdForAdFree();
                    },
                    gradient: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFB800),
                    ],
                  ),
                  _buildDivider(),
                  _buildPremiumFeatureTile(
                    icon: Icons.speed_rounded,
                    title: 'Premium Speed',
                    subtitle: 'Unlock 2x, 3x playback',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showRewardedAdForSpeedBoost();
                    },
                    gradient: [
                      const Color(0xFF4facfe),
                      const Color(0xFF00f2fe),
                    ],
                  ),
                  _buildDivider(),
                  _buildPremiumFeatureTile(
                    icon: Icons.high_quality_rounded,
                    title: 'HD Quality',
                    subtitle: 'Enable HD for all videos',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showRewardedAdForHDQuality();
                    },
                    gradient: [
                      const Color(0xFF11998e),
                      const Color(0xFF38ef7d),
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

  Widget _buildAboutSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.info_rounded,
              title: 'About',
              gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
            ),
            const SizedBox(height: 16),
            _buildGlassCard(
              child: Column(
                children: [
                  _buildPremiumListTile(
                    icon: Icons.info_outline_rounded,
                    title: 'App version',
                    subtitle: 'MediaFlow Pro 1.0.0',
                    onTap: null,
                    gradient: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                    ],
                  ),
                  _buildDivider(),
                  _buildPremiumListTile(
                    icon: Icons.code_rounded,
                    title: 'Open source licenses',
                    subtitle: 'View third-party licenses',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showLicensePage(context);
                    },
                    gradient: [
                      const Color(0xFFf093fb),
                      const Color(0xFFf5576c),
                    ],
                  ),
                  _buildDivider(),
                  _buildPremiumListTile(
                    icon: Icons.star_outline_rounded,
                    title: 'Rate this app',
                    subtitle: 'Share your feedback',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _rateApp(context);
                    },
                    gradient: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFB800),
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
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
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
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
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPremiumToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required List<Color> gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient.map((c) => c.withOpacity(0.2)).toList(),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: gradient[0], size: 24),
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
                    ).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: gradient[0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required List<Color> gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient.map((c) => c.withOpacity(0.2)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: gradient[0], size: 24),
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
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
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
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient.map((c) => c.withOpacity(0.2)).toList(),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: gradient[0],
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.1),
      ),
    );
  }

  // Dialog methods
  void _showAspectRatioDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _showPremiumDialog(
      context: context,
      title: 'Aspect Ratio',
      icon: Icons.aspect_ratio_rounded,
      gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: settingsProvider.availableAspectRatios
            .map(
              (ratio) => _buildRadioOption(
                value: ratio,
                groupValue: settingsProvider.aspectRatio,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setAspectRatio(value);
                  }
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showSubtitleSettings(BuildContext context) {
    _showPremiumDialog(
      context: context,
      title: 'Subtitle Settings',
      icon: Icons.subtitles_rounded,
      gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogTile(
            icon: Icons.format_size_rounded,
            title: 'Font size',
            subtitle: 'Medium',
            onTap: () {
              Navigator.pop(context);
              _showSubtitleFontSizeDialog(context);
            },
          ),
          _buildDialogTile(
            icon: Icons.color_lens_rounded,
            title: 'Font color',
            subtitle: 'White',
            onTap: () {
              Navigator.pop(context);
              _showSubtitleFontColorDialog(context);
            },
          ),
          _buildDialogTile(
            icon: Icons.texture_rounded,
            title: 'Background',
            subtitle: 'Semi-transparent',
            onTap: () {
              Navigator.pop(context);
              _showSubtitleBackgroundDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEqualizerSettings(BuildContext context) {
    _showPremiumDialog(
      context: context,
      title: 'Equalizer',
      icon: Icons.equalizer_rounded,
      gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Equalizer settings will be available in a future update.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showAudioOutputDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _showPremiumDialog(
      context: context,
      title: 'Audio Output',
      icon: Icons.speaker_rounded,
      gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: settingsProvider.availableAudioOutputs
            .map(
              (output) => _buildRadioOption(
                value: output,
                groupValue: settingsProvider.audioOutput,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setAudioOutput(value);
                  }
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showClearRecentDialog(
    BuildContext context,
    MediaProvider mediaProvider,
  ) {
    _showPremiumDialog(
      context: context,
      title: 'Clear Recent Files',
      icon: Icons.delete_rounded,
      gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      content: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Are you sure you want to clear all recent files?',
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            mediaProvider.clearRecentFiles();
            Navigator.pop(context);
            _showStyledSnackBar('Recent files cleared!', Colors.green);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
          ),
          child: const Text('Clear'),
        ),
      ],
    );
  }

  void _showDefaultFolderDialog(BuildContext context) {
    _showPremiumDialog(
      context: context,
      title: 'Default Folder',
      icon: Icons.folder_rounded,
      gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      content: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Default folder selection will be available in a future update.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _scanForMedia(BuildContext context) async {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Scanning...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Searching for media files',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await mediaProvider.refreshMediaFiles();
      if (!context.mounted) return;
      Navigator.pop(context);
      _showStyledSnackBar(
        'Found ${mediaProvider.videoFiles.length + mediaProvider.audioFiles.length} files',
        Colors.green,
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showStyledSnackBar('Error scanning media', Colors.red);
    }
  }

  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'MediaFlow Pro',
      applicationVersion: '1.0.0',
    );
  }

  void _rateApp(BuildContext context) {
    _showPremiumDialog(
      context: context,
      title: 'Rate This App',
      icon: Icons.star_rounded,
      gradient: [const Color(0xFFFFD700), const Color(0xFFFFB800)],
      content: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Thank you for using MediaFlow Pro! Your feedback helps us improve.',
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Open app store
          },
          child: const Text('Rate Now'),
        ),
      ],
    );
  }

  // Rewarded Ad Methods
  void _showRewardedAdForAdFree() {
    if (AdMobService.isRewardedInterstitialAdAvailable) {
      AdMobService.showRewardedInterstitialAd(
        onUserEarnedReward: (ad, RewardItem reward) {
          final settingsProvider = Provider.of<SettingsProvider>(
            context,
            listen: false,
          );
          settingsProvider.activateAdFree();
          _showRewardDialog(
            'Ad-Free Activated!',
            'Enjoy 24 hours without ads!',
            Icons.star_rounded,
            const Color(0xFFFFD700),
          );
        },
      );
    } else {
      _showNoAdAvailableDialog();
    }
  }

  void _showRewardedAdForSpeedBoost() {
    if (AdMobService.isRewardedInterstitialAdAvailable) {
      AdMobService.showRewardedInterstitialAd(
        onUserEarnedReward: (ad, RewardItem reward) {
          final settingsProvider = Provider.of<SettingsProvider>(
            context,
            listen: false,
          );
          settingsProvider.unlockPremiumSpeed();
          _showRewardDialog(
            'Speed Unlocked!',
            'Premium playback speeds available!',
            Icons.speed_rounded,
            const Color(0xFF4facfe),
          );
        },
      );
    } else {
      _showNoAdAvailableDialog();
    }
  }

  void _showRewardedAdForHDQuality() {
    if (AdMobService.isRewardedInterstitialAdAvailable) {
      AdMobService.showRewardedInterstitialAd(
        onUserEarnedReward: (ad, RewardItem reward) {
          final settingsProvider = Provider.of<SettingsProvider>(
            context,
            listen: false,
          );
          settingsProvider.unlockHDQuality();
          _showRewardDialog(
            'HD Quality Unlocked!',
            'HD quality enabled for all videos!',
            Icons.high_quality_rounded,
            const Color(0xFF11998e),
          );
        },
      );
    } else {
      _showNoAdAvailableDialog();
    }
  }

  void _showRewardDialog(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Awesome!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoAdAvailableDialog() {
    _showPremiumDialog(
      context: context,
      title: 'No Ad Available',
      icon: Icons.info_rounded,
      gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      content: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No ads available right now. Please try again later.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper widgets
  void _showPremiumDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required Widget content,
    List<Widget>? actions,
  }) {
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                content,
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                size: 16,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(value),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  void _showStyledSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
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
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSubtitleFontSizeDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _showPremiumDialog(
      context: context,
      title: 'Font Size',
      icon: Icons.format_size_rounded,
      gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: settingsProvider.availableSubtitleFontSizes
            .map(
              (size) => _buildRadioOption(
                value: size,
                groupValue: settingsProvider.subtitleFontSize,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setSubtitleFontSize(value);
                  }
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showSubtitleFontColorDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _showPremiumDialog(
      context: context,
      title: 'Font Color',
      icon: Icons.color_lens_rounded,
      gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: settingsProvider.availableSubtitleFontColors
            .map(
              (color) => _buildRadioOption(
                value: color,
                groupValue: settingsProvider.subtitleFontColor,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setSubtitleFontColor(value);
                  }
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showSubtitleBackgroundDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _showPremiumDialog(
      context: context,
      title: 'Background',
      icon: Icons.texture_rounded,
      gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: settingsProvider.availableSubtitleBackgrounds
            .map(
              (bg) => _buildRadioOption(
                value: bg,
                groupValue: settingsProvider.subtitleBackground,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setSubtitleBackground(value);
                  }
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  // Theme helpers
  IconData _getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Icons.light_mode_rounded;
      case AppTheme.dark:
        return Icons.dark_mode_rounded;
      case AppTheme.ocean:
        return Icons.waves_rounded;
    }
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.ocean:
        return 'Ocean';
    }
  }

  Gradient _getThemeGradient(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        );
      case AppTheme.dark:
        return const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
        );
      case AppTheme.ocean:
        return const LinearGradient(
          colors: [Color(0xFF0F1419), Color(0xFF0891B2)],
        );
    }
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
