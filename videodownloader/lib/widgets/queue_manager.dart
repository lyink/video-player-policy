import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../models/media_file.dart';

class QueueManager extends StatefulWidget {
  const QueueManager({super.key});

  @override
  State<QueueManager> createState() => _QueueManagerState();
}

class _QueueManagerState extends State<QueueManager> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Play Queue'),
            actions: [
              IconButton(
                icon: Icon(
                  playlistProvider.shuffle
                      ? Icons.shuffle
                      : Icons.shuffle_outlined,
                  color: playlistProvider.shuffle
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                onPressed: playlistProvider.toggleShuffle,
                tooltip: 'Shuffle',
              ),
              IconButton(
                icon: Icon(
                  playlistProvider.repeatOne
                      ? Icons.repeat_one
                      : playlistProvider.repeat
                      ? Icons.repeat
                      : Icons.repeat_outlined,
                  color: (playlistProvider.repeat || playlistProvider.repeatOne)
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                onPressed: playlistProvider.toggleRepeat,
                tooltip: playlistProvider.repeatOne
                    ? 'Repeat One'
                    : playlistProvider.repeat
                    ? 'Repeat All'
                    : 'No Repeat',
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(value, playlistProvider),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Clear Queue'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'save',
                    child: ListTile(
                      leading: Icon(Icons.save),
                      title: Text('Save as Playlist'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: playlistProvider.playQueue.isEmpty
              ? _buildEmptyQueue(context, playlistProvider)
              : _buildQueueList(context, playlistProvider),
        );
      },
    );
  }

  Widget _buildEmptyQueue(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    return Center(
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
              Icons.queue_music,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Queue is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add media files to start playing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    return Column(
      children: [
        // Queue Info Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.queue_music, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${playlistProvider.playQueue.length} items in queue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Playing: ${playlistProvider.currentQueueIndex + 1} of ${playlistProvider.playQueue.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPlaybackModeChips(playlistProvider),
            ],
          ),
        ),
        // Queue List
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: playlistProvider.playQueue.length,
            onReorder: (oldIndex, newIndex) {
              playlistProvider.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final mediaFile = playlistProvider.playQueue[index];
              final isCurrentlyPlaying =
                  index == playlistProvider.currentQueueIndex;

              return _buildQueueItem(
                context,
                mediaFile,
                index,
                isCurrentlyPlaying,
                playlistProvider,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackModeChips(PlaylistProvider playlistProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (playlistProvider.shuffle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shuffle,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Shuffle',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (playlistProvider.shuffle &&
            (playlistProvider.repeat || playlistProvider.repeatOne))
          const SizedBox(width: 8),
        if (playlistProvider.repeat || playlistProvider.repeatOne)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  playlistProvider.repeatOne ? Icons.repeat_one : Icons.repeat,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  playlistProvider.repeatOne ? 'Repeat One' : 'Repeat All',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    MediaFile mediaFile,
    int index,
    bool isCurrentlyPlaying,
    PlaylistProvider playlistProvider,
  ) {
    final isVideo = mediaFile.type == MediaType.video;

    return Card(
      key: ValueKey(mediaFile.path),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isCurrentlyPlaying ? 4 : 1,
      color: isCurrentlyPlaying
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Icon(
              Icons.drag_handle,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            // Media type icon
            Container(
              width: 40,
              height: 40,
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
              child: Icon(
                isVideo ? Icons.play_circle : Icons.music_note,
                color: isVideo ? Colors.blue : Colors.green,
                size: 20,
              ),
            ),
          ],
        ),
        title: Text(
          _getDisplayName(mediaFile.name),
          style: TextStyle(
            fontWeight: isCurrentlyPlaying ? FontWeight.w600 : FontWeight.w500,
            color: isCurrentlyPlaying ? Theme.of(context).primaryColor : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              '#${index + 1}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
            if (mediaFile.duration != null) ...[
              Icon(
                Icons.access_time,
                size: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(mediaFile.duration!),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentlyPlaying)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleItemAction(value, index, playlistProvider),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'play',
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Play'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'play_next',
                  child: ListTile(
                    leading: Icon(Icons.skip_next),
                    title: Text('Play Next'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.remove, color: Colors.red),
                    title: Text('Remove', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
        onTap: () => playlistProvider.jumpTo(index),
      ),
    );
  }

  void _handleMenuAction(String action, PlaylistProvider playlistProvider) {
    switch (action) {
      case 'clear':
        _showClearQueueDialog(playlistProvider);
        break;
      case 'save':
        _showSaveAsPlaylistDialog(playlistProvider);
        break;
    }
  }

  void _handleItemAction(
    String action,
    int index,
    PlaylistProvider playlistProvider,
  ) {
    switch (action) {
      case 'play':
        playlistProvider.jumpTo(index);
        break;
      case 'play_next':
        final mediaFile = playlistProvider.playQueue[index];
        playlistProvider.removeFromQueue([index]);
        playlistProvider.addToQueue([mediaFile], playNext: true);
        break;
      case 'remove':
        playlistProvider.removeFromQueue([index]);
        break;
    }
  }

  void _showClearQueueDialog(PlaylistProvider playlistProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Queue'),
        content: const Text('Are you sure you want to clear the entire queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              playlistProvider.clearQueue();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Queue cleared')));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSaveAsPlaylistDialog(PlaylistProvider playlistProvider) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Queue as Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist name',
            hintText: 'Enter playlist name',
          ),
          autofocus: true,
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
                  description: 'Created from play queue',
                  initialFiles: playlistProvider.playQueue,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved queue as "$name" playlist')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      parts.removeLast();
    }
    return parts.join('.');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Mini queue widget for showing in other screens
class MiniQueueWidget extends StatelessWidget {
  const MiniQueueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        if (playlistProvider.playQueue.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentMedia = playlistProvider.currentMedia;
        if (currentMedia == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Now Playing',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${playlistProvider.currentQueueIndex + 1}/${playlistProvider.playQueue.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getDisplayName(currentMedia.name),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: playlistProvider.previous,
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: playlistProvider.next,
                    iconSize: 20,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QueueManager(),
                        ),
                      );
                    },
                    child: const Text('View Queue'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDisplayName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      parts.removeLast();
    }
    return parts.join('.');
  }
}
