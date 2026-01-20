import 'package:flutter/material.dart';
import '../models/media_folder.dart';

class FolderCard extends StatelessWidget {
  final MediaFolder folder;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getFolderColor().withOpacity(0.3),
                      _getFolderColor().withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: _getFolderColor().withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.folder,
                        size: 32,
                        color: _getFolderColor(),
                      ),
                    ),
                    if (folder.videoCount > 0)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.videocam,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (folder.audioCount > 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      folder.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      folder.mediaCountText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getFolderColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getShortPath(folder.path),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getFolderColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getFolderColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${folder.totalMediaCount}',
                  style: TextStyle(
                    color: _getFolderColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFolderColor() {
    if (folder.videoCount > 0 && folder.audioCount > 0) {
      return Colors.purple;
    } else if (folder.videoCount > 0) {
      return Colors.blue;
    } else if (folder.audioCount > 0) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _getShortPath(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    if (parts.length <= 2) return path;
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }
}