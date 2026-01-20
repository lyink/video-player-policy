import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/media_file.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final bool showMenuButton;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onExport,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPlaylistIcon(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (playlist.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              playlist.description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showMenuButton) _buildMenuButton(context),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      context,
                      icon: Icons.music_note,
                      label: '${playlist.itemCount} items',
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    if (playlist.totalDuration.inSeconds > 0)
                      _buildInfoChip(
                        context,
                        icon: Icons.access_time,
                        label: _formatDuration(playlist.totalDuration),
                        color: Colors.blue,
                      ),
                    const SizedBox(width: 8),
                    _buildTypeChip(context),
                  ],
                ),
                if (playlist.type == PlaylistType.smart &&
                    playlist.smartRules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSmartRulesPreview(context),
                ],
                if (playlist.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMediaPreview(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistIcon() {
    return Builder(
      builder: (context) {
        IconData iconData;
        Color iconColor;

        switch (playlist.type) {
          case PlaylistType.favorites:
            iconData = Icons.favorite;
            iconColor = Colors.red;
            break;
          case PlaylistType.recent:
            iconData = Icons.history;
            iconColor = ThemeColors.getIconOrangeColor(context, Provider.of<ThemeProvider>(context, listen: false));
            break;
          case PlaylistType.smart:
            iconData = Icons.auto_awesome;
            iconColor = Colors.purple;
            break;
          case PlaylistType.queue:
            iconData = Icons.queue_music;
            iconColor = Colors.green;
            break;
          case PlaylistType.folder:
            iconData = Icons.folder;
            iconColor = Colors.brown;
            break;
          default:
            iconData = Icons.playlist_play;
            iconColor = Colors.blue;
        }

        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [iconColor, iconColor.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(iconData, color: Colors.white, size: 28),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'duplicate':
            onDuplicate?.call();
            break;
          case 'export':
            onExport?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onDuplicate != null)
          const PopupMenuItem(
            value: 'duplicate',
            child: ListTile(
              leading: Icon(Icons.copy),
              title: Text('Duplicate'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onExport != null)
          const PopupMenuItem(
            value: 'export',
            child: ListTile(
              leading: Icon(Icons.file_download),
              title: Text('Export'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onDelete != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_vert, size: 20),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    String label;
    Color color;

    switch (playlist.type) {
      case PlaylistType.smart:
        label = 'Smart';
        color = Colors.purple;
        break;
      case PlaylistType.favorites:
        label = 'Favorites';
        color = Colors.red;
        break;
      case PlaylistType.recent:
        label = 'Recent';
        color = ThemeColors.getIconOrangeColor(context, Provider.of<ThemeProvider>(context, listen: false));
        break;
      case PlaylistType.queue:
        label = 'Queue';
        color = Colors.green;
        break;
      case PlaylistType.folder:
        label = 'Folder';
        color = Colors.brown;
        break;
      default:
        label = 'Manual';
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSmartRulesPreview(BuildContext context) {
    final rule = playlist.smartRules.first;
    String ruleText = '${rule.criteria.name} ${rule.operator} ${rule.value}';

    if (playlist.smartRules.length > 1) {
      ruleText += ' (+${playlist.smartRules.length - 1} more)';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.rule, size: 16, color: Colors.purple.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ruleText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    final previewItems = playlist.items.take(4).toList();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: previewItems.length,
        itemBuilder: (context, index) {
          final item = previewItems[index];
          final isVideo = item.mediaFile.type == MediaType.video;

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isVideo
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isVideo
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isVideo ? Icons.play_circle : Icons.music_note,
                  color: isVideo ? Colors.blue : Colors.green,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  _getDisplayName(item.mediaFile.name),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getDisplayName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      parts.removeLast();
    }
    final name = parts.join('.');
    return name.length > 10 ? '${name.substring(0, 10)}...' : name;
  }
}
