import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/media_provider.dart';
import '../models/playlist.dart';
import '../models/media_file.dart';
import '../widgets/playlist_card.dart';
import '../widgets/smart_playlist_creator.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_widget.dart';
import '../services/admob_service.dart';

class AdvancedPlaylistsScreen extends StatefulWidget {
  const AdvancedPlaylistsScreen({super.key});

  @override
  State<AdvancedPlaylistsScreen> createState() =>
      _AdvancedPlaylistsScreenState();
}

class _AdvancedPlaylistsScreenState extends State<AdvancedPlaylistsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  PlaylistSortBy _sortBy = PlaylistSortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlaylistProvider, MediaProvider>(
      builder: (context, playlistProvider, mediaProvider, child) {
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Playlists',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.8),
                            Theme.of(context).primaryColor.withOpacity(0.4),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 20,
                            top: 60,
                            child: Icon(
                              Icons.queue_music,
                              size: 120,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${playlistProvider.playlists.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Playlists',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _showSearchDialog,
                      tooltip: 'Search playlists',
                    ),
                    PopupMenuButton<String>(
                      onSelected: _handleMenuAction,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'sort',
                          child: ListTile(
                            leading: Icon(Icons.sort),
                            title: Text('Sort'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: ListTile(
                            leading: Icon(Icons.file_upload),
                            title: Text('Import'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'templates',
                          child: ListTile(
                            leading: Icon(Icons.auto_awesome),
                            title: Text('Templates'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'All', icon: Icon(Icons.list, size: 20)),
                      Tab(
                        text: 'Manual',
                        icon: Icon(Icons.playlist_add, size: 20),
                      ),
                      Tab(
                        text: 'Smart',
                        icon: Icon(Icons.auto_awesome, size: 20),
                      ),
                      Tab(text: 'System', icon: Icon(Icons.star, size: 20)),
                    ],
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAllPlaylistsTab(playlistProvider),
                _buildManualPlaylistsTab(playlistProvider),
                _buildSmartPlaylistsTab(playlistProvider),
                _buildSystemPlaylistsTab(playlistProvider),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(
            context,
            playlistProvider,
          ),
        );
      },
    );
  }

  Widget _buildAllPlaylistsTab(PlaylistProvider playlistProvider) {
    final filteredPlaylists = _filterAndSortPlaylists(
      playlistProvider.playlists,
    );

    if (filteredPlaylists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.playlist_add,
        title: 'No playlists found',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try adjusting your search terms'
            : 'Create your first playlist to get started',
        actionLabel: 'Create Playlist',
        onAction: () => _showCreatePlaylistDialog(context, playlistProvider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPlaylists.length + 2, // Add space for ads
      itemBuilder: (context, index) {
        // Show banner ad at the top
        if (index == 0) {
          return const BannerAdWidget(showAlways: true);
        }
        // Show native ad in the middle
        if (index == (filteredPlaylists.length ~/ 2) + 1) {
          return const NativeAdWidget();
        }

        // Adjust index for playlists
        final playlistIndex = index > (filteredPlaylists.length ~/ 2) + 1 ? index - 2 : index - 1;
        if (playlistIndex < 0 || playlistIndex >= filteredPlaylists.length) {
          return const SizedBox.shrink();
        }

        final playlist = filteredPlaylists[playlistIndex];
        return PlaylistCard(
          playlist: playlist,
          onTap: () => _openPlaylist(context, playlist),
          onEdit: () => _editPlaylist(context, playlistProvider, playlist),
          onDelete: () => _deletePlaylist(context, playlistProvider, playlist),
          onDuplicate: () => _duplicatePlaylist(playlistProvider, playlist),
          onExport: () => _exportPlaylist(context, playlistProvider, playlist),
        );
      },
    );
  }

  Widget _buildManualPlaylistsTab(PlaylistProvider playlistProvider) {
    final manualPlaylists = _filterAndSortPlaylists(
      playlistProvider.manualPlaylists,
    );

    if (manualPlaylists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.playlist_add,
        title: 'No manual playlists',
        subtitle: 'Create custom playlists with your favorite media',
        actionLabel: 'Create Manual Playlist',
        onAction: () => _showCreatePlaylistDialog(context, playlistProvider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: manualPlaylists.length + 1, // Add space for banner ad
      itemBuilder: (context, index) {
        // Show banner ad at the top
        if (index == 0) {
          return const BannerAdWidget(showAlways: true);
        }

        final playlistIndex = index - 1;
        final playlist = manualPlaylists[playlistIndex];
        return PlaylistCard(
          playlist: playlist,
          onTap: () => _openPlaylist(context, playlist),
          onEdit: () => _editPlaylist(context, playlistProvider, playlist),
          onDelete: () => _deletePlaylist(context, playlistProvider, playlist),
          onDuplicate: () => _duplicatePlaylist(playlistProvider, playlist),
          onExport: () => _exportPlaylist(context, playlistProvider, playlist),
        );
      },
    );
  }

  Widget _buildSmartPlaylistsTab(PlaylistProvider playlistProvider) {
    final smartPlaylists = _filterAndSortPlaylists(
      playlistProvider.smartPlaylists,
    );

    if (smartPlaylists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        title: 'No smart playlists',
        subtitle: 'Create dynamic playlists that update automatically',
        actionLabel: 'Create Smart Playlist',
        onAction: () => _showSmartPlaylistCreator(context, playlistProvider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: smartPlaylists.length + 1, // Add space for native ad
      itemBuilder: (context, index) {
        // Show native ad at the top
        if (index == 0) {
          return const NativeAdWidget();
        }

        final playlistIndex = index - 1;
        final playlist = smartPlaylists[playlistIndex];
        return PlaylistCard(
          playlist: playlist,
          onTap: () => _openPlaylist(context, playlist),
          onEdit: () => _editSmartPlaylist(context, playlistProvider, playlist),
          onDelete: () => _deletePlaylist(context, playlistProvider, playlist),
          onDuplicate: () => _duplicatePlaylist(playlistProvider, playlist),
          onExport: () => _exportPlaylist(context, playlistProvider, playlist),
        );
      },
    );
  }

  Widget _buildSystemPlaylistsTab(PlaylistProvider playlistProvider) {
    final systemPlaylists = playlistProvider.playlists
        .where(
          (p) =>
              p.type == PlaylistType.favorites || p.type == PlaylistType.recent,
        )
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: systemPlaylists.length + 1, // Add space for banner ad
      itemBuilder: (context, index) {
        // Show banner ad at the top
        if (index == 0) {
          return const BannerAdWidget(showAlways: true);
        }

        final playlistIndex = index - 1;
        final playlist = systemPlaylists[playlistIndex];
        return PlaylistCard(
          playlist: playlist,
          onTap: () => _openPlaylist(context, playlist),
          showMenuButton: false, // System playlists can't be deleted
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateOptionsDialog(context, playlistProvider),
      icon: const Icon(Icons.add),
      label: const Text('Create'),
      tooltip: 'Create new playlist',
    );
  }

  List<Playlist> _filterAndSortPlaylists(List<Playlist> playlists) {
    var filtered = playlists.where((playlist) {
      if (_searchQuery.isEmpty) return true;
      return playlist.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          playlist.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case PlaylistSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case PlaylistSortBy.dateAdded:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case PlaylistSortBy.lastModified:
          comparison = a.lastModified.compareTo(b.lastModified);
          break;
        default:
          comparison = a.itemCount.compareTo(b.itemCount);
          break;
      }

      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Playlists'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter playlist name...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort':
        _showSortDialog();
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'templates':
        _showTemplatesDialog();
        break;
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Playlists'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sort by'),
              subtitle: DropdownButton<PlaylistSortBy>(
                value: _sortBy,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: PlaylistSortBy.name,
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: PlaylistSortBy.dateAdded,
                    child: Text('Date Created'),
                  ),
                  DropdownMenuItem(
                    value: PlaylistSortBy.lastModified,
                    child: Text('Last Modified'),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Order'),
              subtitle: DropdownButton<SortOrder>(
                value: _sortOrder,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: SortOrder.ascending,
                    child: Text('Ascending'),
                  ),
                  DropdownMenuItem(
                    value: SortOrder.descending,
                    child: Text('Descending'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    // TODO: Implement import dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon')),
    );
  }

  void _showTemplatesDialog() {
    final playlistProvider = Provider.of<PlaylistProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist Templates'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: PlaylistTemplate.predefinedTemplates.length,
            itemBuilder: (context, index) {
              final template = PlaylistTemplate.predefinedTemplates[index];
              return ListTile(
                leading: Icon(
                  template.type == PlaylistType.smart
                      ? Icons.auto_awesome
                      : Icons.playlist_add,
                ),
                title: Text(template.name),
                subtitle: Text(template.description),
                onTap: () async {
                  Navigator.pop(context);
                  await playlistProvider.createFromTemplate(template);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Created "${template.name}" playlist'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCreateOptionsDialog(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Manual Playlist'),
              subtitle: const Text('Create a custom playlist'),
              onTap: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, playlistProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Smart Playlist'),
              subtitle: const Text('Auto-updating based on rules'),
              onTap: () {
                Navigator.pop(context);
                _showSmartPlaylistCreator(context, playlistProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize),
              title: const Text('From Template'),
              subtitle: const Text('Use predefined templates'),
              onTap: () {
                Navigator.pop(context);
                _showTemplatesDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Manual Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist name',
                hintText: 'Enter playlist name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await playlistProvider.createManualPlaylist(
                  name: name,
                  description: descriptionController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created "$name" playlist')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSmartPlaylistCreator(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    // TODO: Implement smart playlist creator widget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Smart playlist creator coming soon')),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    // Show interstitial ad before opening playlist
    AdMobService.showInterstitialAdIfAvailable();

    // TODO: Navigate to playlist detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening "${playlist.name}" playlist')),
    );
  }

  void _editPlaylist(
    BuildContext context,
    PlaylistProvider playlistProvider,
    Playlist playlist,
  ) {
    // TODO: Implement playlist editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing "${playlist.name}" playlist')),
    );
  }

  void _editSmartPlaylist(
    BuildContext context,
    PlaylistProvider playlistProvider,
    Playlist playlist,
  ) {
    // TODO: Implement smart playlist editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing smart playlist "${playlist.name}"')),
    );
  }

  void _deletePlaylist(
    BuildContext context,
    PlaylistProvider playlistProvider,
    Playlist playlist,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await playlistProvider.deletePlaylist(playlist.id);
              if (context.mounted) {
                Navigator.pop(context);
                // Show interstitial ad after deleting
                AdMobService.showInterstitialAdIfAvailable();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${playlist.name}" playlist'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicatePlaylist(
    PlaylistProvider playlistProvider,
    Playlist playlist,
  ) async {
    final duplicate = await playlistProvider.duplicatePlaylist(playlist.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duplicated as "${duplicate.name}"')),
      );
    }
  }

  void _exportPlaylist(
    BuildContext context,
    PlaylistProvider playlistProvider,
    Playlist playlist,
  ) {
    // TODO: Implement playlist export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting "${playlist.name}" playlist')),
    );
  }
}
