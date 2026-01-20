import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'media_file.dart';

enum PlaylistType {
  manual, // User-created playlists
  smart, // Auto-generated based on criteria
  recent, // Recently played
  favorites, // Favorite items
  queue, // Current play queue
  folder, // Folder-based playlist
  mostPlayed, // Most played tracks
  neverPlayed, // Never played tracks
}

enum SmartPlaylistCriteria {
  genre,
  artist,
  album,
  year,
  duration,
  fileSize,
  dateAdded,
  lastPlayed,
  playCount,
  fileType,
  folderPath,
}

enum SortOrder { ascending, descending }

enum PlaylistSortBy {
  name,
  dateAdded,
  duration,
  fileSize,
  lastModified,
  artist,
  album,
  year,
  playCount,
  rating,
  custom, // Manual ordering
}

class SmartPlaylistRule {
  final SmartPlaylistCriteria criteria;
  final String
  operator; // 'equals', 'contains', 'greater_than', 'less_than', 'starts_with', 'ends_with'
  final String value;
  final bool caseSensitive;

  SmartPlaylistRule({
    required this.criteria,
    required this.operator,
    required this.value,
    this.caseSensitive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'criteria': criteria.name,
      'operator': operator,
      'value': value,
      'caseSensitive': caseSensitive,
    };
  }

  factory SmartPlaylistRule.fromJson(Map<String, dynamic> json) {
    return SmartPlaylistRule(
      criteria: SmartPlaylistCriteria.values.firstWhere(
        (e) => e.name == json['criteria'],
        orElse: () => SmartPlaylistCriteria.genre,
      ),
      operator: json['operator'] ?? 'equals',
      value: json['value'] ?? '',
      caseSensitive: json['caseSensitive'] ?? false,
    );
  }

  bool matches(MediaFile mediaFile) {
    String fieldValue = _getFieldValue(mediaFile);
    String compareValue = caseSensitive ? value : value.toLowerCase();
    String actualValue = caseSensitive ? fieldValue : fieldValue.toLowerCase();

    switch (operator) {
      case 'equals':
        return actualValue == compareValue;
      case 'contains':
        return actualValue.contains(compareValue);
      case 'starts_with':
        return actualValue.startsWith(compareValue);
      case 'ends_with':
        return actualValue.endsWith(compareValue);
      case 'greater_than':
        return _compareNumeric(fieldValue, value) > 0;
      case 'less_than':
        return _compareNumeric(fieldValue, value) < 0;
      case 'greater_equal':
        return _compareNumeric(fieldValue, value) >= 0;
      case 'less_equal':
        return _compareNumeric(fieldValue, value) <= 0;
      default:
        return false;
    }
  }

  String _getFieldValue(MediaFile mediaFile) {
    switch (criteria) {
      case SmartPlaylistCriteria.genre:
        return mediaFile.metadata?['genre'] ?? '';
      case SmartPlaylistCriteria.artist:
        return mediaFile.metadata?['artist'] ?? '';
      case SmartPlaylistCriteria.album:
        return mediaFile.metadata?['album'] ?? '';
      case SmartPlaylistCriteria.year:
        return mediaFile.metadata?['year']?.toString() ?? '';
      case SmartPlaylistCriteria.duration:
        return mediaFile.duration?.inSeconds.toString() ?? '0';
      case SmartPlaylistCriteria.fileSize:
        return mediaFile.size?.toString() ?? '0';
      case SmartPlaylistCriteria.dateAdded:
        return mediaFile.dateAdded?.millisecondsSinceEpoch.toString() ?? '0';
      case SmartPlaylistCriteria.lastPlayed:
        return mediaFile.lastPlayed?.millisecondsSinceEpoch.toString() ?? '0';
      case SmartPlaylistCriteria.playCount:
        return mediaFile.playCount.toString();
      case SmartPlaylistCriteria.fileType:
        return mediaFile.extension;
      case SmartPlaylistCriteria.folderPath:
        return File(mediaFile.path).parent.path;
      default:
        return mediaFile.name;
    }
  }

  int _compareNumeric(String a, String b) {
    final numA = double.tryParse(a) ?? 0;
    final numB = double.tryParse(b) ?? 0;
    return numA.compareTo(numB);
  }
}

class PlaylistItem {
  final MediaFile mediaFile;
  final DateTime dateAdded;
  final int position;
  final Map<String, dynamic> metadata;

  PlaylistItem({
    required this.mediaFile,
    required this.dateAdded,
    required this.position,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'mediaFile': mediaFile.toJson(),
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'position': position,
      'metadata': metadata,
    };
  }

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      mediaFile: MediaFile.fromJson(json['mediaFile']),
      dateAdded: DateTime.fromMillisecondsSinceEpoch(json['dateAdded']),
      position: json['position'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final PlaylistType type;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<PlaylistItem> items;
  final List<SmartPlaylistRule> smartRules;
  final PlaylistSortBy sortBy;
  final SortOrder sortOrder;
  final String? coverImagePath;
  final Map<String, dynamic> metadata;
  final bool isAutoUpdate; // For smart playlists
  final int maxItems; // Limit for smart playlists
  final bool shuffle;
  final bool repeat;
  final IconData? icon;
  final Color? color;
  final bool isSystem;

  Playlist({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.createdAt,
    required this.lastModified,
    this.items = const [],
    this.smartRules = const [],
    this.sortBy = PlaylistSortBy.custom,
    this.sortOrder = SortOrder.ascending,
    this.coverImagePath,
    this.metadata = const {},
    this.isAutoUpdate = false,
    this.maxItems = 1000,
    this.shuffle = false,
    this.repeat = false,
    this.icon,
    this.color,
    this.isSystem = false,
  });

  int get itemCount => items.length;

  Duration get totalDuration {
    return items.fold(Duration.zero, (total, item) {
      return total + (item.mediaFile.duration ?? Duration.zero);
    });
  }

  int get totalSize {
    return items.fold(0, (total, item) {
      return total + (item.mediaFile.size ?? 0);
    });
  }

  List<MediaFile> get mediaFiles =>
      items.map((item) => item.mediaFile).toList();

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    PlaylistType? type,
    DateTime? createdAt,
    DateTime? lastModified,
    List<PlaylistItem>? items,
    List<SmartPlaylistRule>? smartRules,
    PlaylistSortBy? sortBy,
    SortOrder? sortOrder,
    String? coverImagePath,
    Map<String, dynamic>? metadata,
    bool? isAutoUpdate,
    int? maxItems,
    bool? shuffle,
    bool? repeat,
    IconData? icon,
    Color? color,
    bool? isSystem,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      items: items ?? this.items,
      smartRules: smartRules ?? this.smartRules,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      metadata: metadata ?? this.metadata,
      isAutoUpdate: isAutoUpdate ?? this.isAutoUpdate,
      maxItems: maxItems ?? this.maxItems,
      shuffle: shuffle ?? this.shuffle,
      repeat: repeat ?? this.repeat,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'items': items.map((item) => item.toJson()).toList(),
      'smartRules': smartRules.map((rule) => rule.toJson()).toList(),
      'sortBy': sortBy.name,
      'sortOrder': sortOrder.name,
      'coverImagePath': coverImagePath,
      'metadata': metadata,
      'isAutoUpdate': isAutoUpdate,
      'maxItems': maxItems,
      'shuffle': shuffle,
      'repeat': repeat,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: PlaylistType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlaylistType.manual,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        json['lastModified'] ?? 0,
      ),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => PlaylistItem.fromJson(item))
              .toList() ??
          [],
      smartRules:
          (json['smartRules'] as List<dynamic>?)
              ?.map((rule) => SmartPlaylistRule.fromJson(rule))
              .toList() ??
          [],
      sortBy: PlaylistSortBy.values.firstWhere(
        (e) => e.name == json['sortBy'],
        orElse: () => PlaylistSortBy.custom,
      ),
      sortOrder: SortOrder.values.firstWhere(
        (e) => e.name == json['sortOrder'],
        orElse: () => SortOrder.ascending,
      ),
      coverImagePath: json['coverImagePath'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isAutoUpdate: json['isAutoUpdate'] ?? false,
      maxItems: json['maxItems'] ?? 1000,
      shuffle: json['shuffle'] ?? false,
      repeat: json['repeat'] ?? false,
    );
  }

  // Export playlist to M3U format
  String toM3U() {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');

    for (final item in items) {
      final duration = item.mediaFile.duration?.inSeconds ?? -1;
      final title = item.mediaFile.metadata?['title'] ?? item.mediaFile.name;
      buffer.writeln('#EXTINF:$duration,$title');
      buffer.writeln(item.mediaFile.path);
    }

    return buffer.toString();
  }

  // Export playlist to PLS format
  String toPLS() {
    final buffer = StringBuffer();
    buffer.writeln('[playlist]');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final title = item.mediaFile.metadata?['title'] ?? item.mediaFile.name;
      final duration = item.mediaFile.duration?.inSeconds ?? -1;

      buffer.writeln('File${i + 1}=${item.mediaFile.path}');
      buffer.writeln('Title${i + 1}=$title');
      buffer.writeln('Length${i + 1}=$duration');
    }

    buffer.writeln('NumberOfEntries=${items.length}');
    buffer.writeln('Version=2');

    return buffer.toString();
  }

  // Export to XSPF format (VLC-compatible)
  String toXSPF() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<playlist version="1" xmlns="http://xspf.org/ns/0/">');
    buffer.writeln('  <title>$name</title>');
    buffer.writeln('  <trackList>');

    for (final item in items) {
      buffer.writeln('    <track>');
      buffer.writeln('      <location>file://${item.mediaFile.path}</location>');
      final title = item.mediaFile.metadata?['title'] ?? item.mediaFile.name;
      buffer.writeln('      <title>$title</title>');
      if (item.mediaFile.duration != null) {
        buffer.writeln('      <duration>${item.mediaFile.duration!.inMilliseconds}</duration>');
      }
      buffer.writeln('    </track>');
    }

    buffer.writeln('  </trackList>');
    buffer.writeln('</playlist>');

    return buffer.toString();
  }

  // Create a smart playlist from rules
  static Playlist createSmart({
    required String name,
    required List<SmartPlaylistRule> rules,
    String description = '',
    PlaylistSortBy sortBy = PlaylistSortBy.name,
    SortOrder sortOrder = SortOrder.ascending,
    int maxItems = 1000,
    bool isAutoUpdate = true,
    IconData? icon,
    Color? color,
  }) {
    return Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      type: PlaylistType.smart,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      smartRules: rules,
      sortBy: sortBy,
      sortOrder: sortOrder,
      maxItems: maxItems,
      isAutoUpdate: isAutoUpdate,
      icon: icon,
      color: color,
    );
  }

  // Create a manual playlist
  static Playlist createManual({
    required String name,
    String description = '',
    List<MediaFile> initialFiles = const [],
    IconData? icon,
    Color? color,
  }) {
    final now = DateTime.now();
    final items = initialFiles.asMap().entries.map((entry) {
      return PlaylistItem(
        mediaFile: entry.value,
        dateAdded: now,
        position: entry.key,
      );
    }).toList();

    return Playlist(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      type: PlaylistType.manual,
      createdAt: now,
      lastModified: now,
      items: items,
      icon: icon,
      color: color,
    );
  }
}

// Playlist templates for quick creation
class PlaylistTemplate {
  final String name;
  final String description;
  final PlaylistType type;
  final List<SmartPlaylistRule> rules;
  final PlaylistSortBy sortBy;
  final SortOrder sortOrder;
  final int maxItems;

  const PlaylistTemplate({
    required this.name,
    required this.description,
    required this.type,
    this.rules = const [],
    this.sortBy = PlaylistSortBy.name,
    this.sortOrder = SortOrder.ascending,
    this.maxItems = 1000,
  });

  Playlist createPlaylist() {
    if (type == PlaylistType.smart) {
      return Playlist.createSmart(
        name: name,
        description: description,
        rules: rules,
        sortBy: sortBy,
        sortOrder: sortOrder,
        maxItems: maxItems,
      );
    } else {
      return Playlist.createManual(name: name, description: description);
    }
  }

  static final List<PlaylistTemplate> predefinedTemplates = [
    PlaylistTemplate(
      name: 'Recently Added',
      description: 'Files added in the last 7 days',
      type: PlaylistType.smart,
      rules: [
        SmartPlaylistRule(
          criteria: SmartPlaylistCriteria.dateAdded,
          operator: 'greater_than',
          value: '7', // days ago
        ),
      ],
      sortBy: PlaylistSortBy.dateAdded,
      sortOrder: SortOrder.descending,
      maxItems: 100,
    ),
    PlaylistTemplate(
      name: 'Large Files',
      description: 'Files larger than 100MB',
      type: PlaylistType.smart,
      rules: [
        SmartPlaylistRule(
          criteria: SmartPlaylistCriteria.fileSize,
          operator: 'greater_than',
          value: '104857600', // 100MB in bytes
        ),
      ],
      sortBy: PlaylistSortBy.fileSize,
      sortOrder: SortOrder.descending,
    ),
    PlaylistTemplate(
      name: 'Long Videos',
      description: 'Videos longer than 30 minutes',
      type: PlaylistType.smart,
      rules: [
        SmartPlaylistRule(
          criteria: SmartPlaylistCriteria.fileType,
          operator: 'equals',
          value: 'video',
        ),
        SmartPlaylistRule(
          criteria: SmartPlaylistCriteria.duration,
          operator: 'greater_than',
          value: '1800', // 30 minutes in seconds
        ),
      ],
      sortBy: PlaylistSortBy.duration,
      sortOrder: SortOrder.descending,
    ),
    PlaylistTemplate(
      name: 'Music Collection',
      description: 'All audio files',
      type: PlaylistType.smart,
      rules: [
        SmartPlaylistRule(
          criteria: SmartPlaylistCriteria.fileType,
          operator: 'equals',
          value: 'audio',
        ),
      ],
      sortBy: PlaylistSortBy.name,
      sortOrder: SortOrder.ascending,
    ),
  ];
}
