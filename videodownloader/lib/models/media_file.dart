import 'dart:io';
import 'package:mime/mime.dart';

class MediaFile {
  final String path;
  final String name;
  final String extension;
  final MediaType type;
  final int? size;
  final DateTime? lastModified;
  String? thumbnail;
  Duration? duration;
  Map<String, dynamic>? metadata;
  DateTime? dateAdded;
  DateTime? lastPlayed;
  int playCount;
  int? rating;

  MediaFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.type,
    this.size,
    this.lastModified,
    this.thumbnail,
    this.duration,
    this.metadata,
    this.dateAdded,
    this.lastPlayed,
    this.playCount = 0,
    this.rating,
  });

  static MediaFile fromFile(File file) {
    final name = file.uri.pathSegments.last;
    final extension = name.split('.').last.toLowerCase();
    final mimeType = lookupMimeType(file.path);

    MediaType type;
    if (mimeType != null && mimeType.startsWith('video/')) {
      type = MediaType.video;
    } else if (mimeType != null && mimeType.startsWith('audio/')) {
      type = MediaType.audio;
    } else if (_videoExtensions.contains(extension)) {
      type = MediaType.video;
    } else if (_audioExtensions.contains(extension)) {
      type = MediaType.audio;
    } else {
      type = MediaType.unknown;
    }

    return MediaFile(
      path: file.path,
      name: name,
      extension: extension,
      type: type,
      size: file.existsSync() ? file.lengthSync() : null,
      lastModified: file.existsSync() ? file.lastModifiedSync() : null,
      dateAdded: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'extension': extension,
      'type': type.name,
      'size': size,
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'thumbnail': thumbnail,
      'duration': duration?.inMilliseconds,
      'metadata': metadata,
      'dateAdded': dateAdded?.millisecondsSinceEpoch,
      'lastPlayed': lastPlayed?.millisecondsSinceEpoch,
      'playCount': playCount,
      'rating': rating,
    };
  }

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      path: json['path'] ?? '',
      name: json['name'] ?? '',
      extension: json['extension'] ?? '',
      type: MediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MediaType.unknown,
      ),
      size: json['size'],
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : null,
      thumbnail: json['thumbnail'],
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      dateAdded: json['dateAdded'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateAdded'])
          : null,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayed'])
          : null,
      playCount: json['playCount'] ?? 0,
      rating: json['rating'],
    );
  }

  String get formattedSize {
    if (size == null) return 'Unknown';

    const units = ['B', 'KB', 'MB', 'GB'];
    double bytes = size!.toDouble();
    int unitIndex = 0;

    while (bytes >= 1024 && unitIndex < units.length - 1) {
      bytes /= 1024;
      unitIndex++;
    }

    return '${bytes.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  static const List<String> _videoExtensions = [
    'mp4',
    'avi',
    'mkv',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm4v',
    '3gp',
    'mpg',
    'mpeg',
    'ts',
    'mts',
  ];

  static const List<String> _audioExtensions = [
    'mp3',
    'wav',
    'flac',
    'aac',
    'ogg',
    'wma',
    'm4a',
    'opus',
    'ape',
    'alac',
    'ac3',
  ];

  static List<String> get supportedExtensions => [
    ..._videoExtensions,
    ..._audioExtensions,
  ];
  static List<String> get videoExtensions => _videoExtensions;
  static List<String> get audioExtensions => _audioExtensions;
}

enum MediaType { video, audio, unknown }
