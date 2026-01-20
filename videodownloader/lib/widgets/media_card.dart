import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_file.dart';
import '../providers/playlist_provider.dart';

class MediaCard extends StatelessWidget {
  final MediaFile media;
  final VoidCallback onTap;
  final bool showDetails;

  const MediaCard({
    super.key,
    required this.media,
    required this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final isFavorite = playlistProvider.isFavorite(media);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: showDetails
                ? _buildListTile(context, isFavorite, playlistProvider)
                : _buildCompactCard(context, isFavorite, playlistProvider),
          ),
        );
      },
    );
  }

  Widget _buildListTile(BuildContext context, bool isFavorite, PlaylistProvider playlistProvider) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: media.type == MediaType.video
            ? Colors.blue.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        child: Icon(
          media.type == MediaType.video
              ? Icons.videocam
              : Icons.music_note,
          color: media.type == MediaType.video
              ? Colors.blue
              : Colors.green,
        ),
      ),
      title: Text(
        _getDisplayName(media.name),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            media.formattedSize,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (media.lastModified != null)
            Text(
              _formatDate(media.lastModified!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (media.duration != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(media.duration!),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              if (isFavorite) {
                await playlistProvider.removeFromFavorites(media);
              } else {
                await playlistProvider.addToFavorites(media);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, bool isFavorite, PlaylistProvider playlistProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (media.type == MediaType.video ? Colors.blue : Colors.green).withOpacity(0.3),
                  (media.type == MediaType.video ? Colors.blue : Colors.green).withOpacity(0.1),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background for video preview effect
                if (media.type == MediaType.video) ...[
                  // Simulate video thumbnail with layered design
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.grey[900]!.withOpacity(0.6),
                          Colors.blue.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Video frame effect
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
                // Center content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: media.type == MediaType.video
                              ? Colors.white.withOpacity(0.9)
                              : Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: media.type == MediaType.video ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          media.type == MediaType.video
                              ? Icons.play_arrow
                              : Icons.music_note,
                          size: 32,
                          color: media.type == MediaType.video ? Colors.black87 : Colors.green[700],
                        ),
                      ),
                      if (media.duration != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _formatDuration(media.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Video type indicator
                if (media.type == MediaType.video)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            'HD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: 56,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getDisplayName(media.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () async {
                          if (isFavorite) {
                            await playlistProvider.removeFromFavorites(media);
                          } else {
                            await playlistProvider.addToFavorites(media);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                media.formattedSize,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDisplayName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      parts.removeLast(); // Remove extension
    }
    return parts.join('.');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}