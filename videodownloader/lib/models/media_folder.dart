import 'dart:io';
import 'media_file.dart';

class MediaFolder {
  final String path;
  final String name;
  final List<MediaFile> mediaFiles;
  final DateTime? lastModified;
  final int videoCount;
  final int audioCount;

  MediaFolder({
    required this.path,
    required this.name,
    required this.mediaFiles,
    this.lastModified,
    required this.videoCount,
    required this.audioCount,
  });

  factory MediaFolder.fromDirectory(Directory directory, List<MediaFile> mediaFiles) {
    final videoFiles = mediaFiles.where((file) => file.type == MediaType.video).length;
    final audioFiles = mediaFiles.where((file) => file.type == MediaType.audio).length;

    return MediaFolder(
      path: directory.path,
      name: directory.path.split(Platform.pathSeparator).last,
      mediaFiles: mediaFiles,
      lastModified: directory.statSync().modified,
      videoCount: videoFiles,
      audioCount: audioFiles,
    );
  }

  int get totalMediaCount => videoCount + audioCount;

  String get displayName {
    if (name.isEmpty) return 'Root';
    return name;
  }

  String get mediaCountText {
    if (videoCount > 0 && audioCount > 0) {
      return '$videoCount videos, $audioCount audio';
    } else if (videoCount > 0) {
      return '$videoCount video${videoCount > 1 ? 's' : ''}';
    } else if (audioCount > 0) {
      return '$audioCount audio${audioCount > 1 ? ' files' : ' file'}';
    } else {
      return 'No media';
    }
  }
}