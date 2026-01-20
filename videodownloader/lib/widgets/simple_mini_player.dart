import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/modern_audio_player.dart';
import '../models/media_file.dart';

class SimpleMiniPlayer extends StatelessWidget {
  final MediaFile currentMedia;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final List<MediaFile>? playlist;
  final int? currentIndex;

  const SimpleMiniPlayer({
    super.key,
    required this.currentMedia,
    required this.isPlaying,
    required this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.playlist,
    this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ModernAudioPlayer(
                  media: currentMedia,
                  playlist: playlist,
                  currentIndex: currentIndex,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Album art
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentMedia.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unknown Artist',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onPrevious != null)
                    IconButton(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 20,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
                    ),

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                    ),
                    child: IconButton(
                      onPressed: onPlayPause,
                      icon: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  if (onNext != null)
                    IconButton(
                      onPressed: onNext,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 20,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}