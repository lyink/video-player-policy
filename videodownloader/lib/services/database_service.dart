import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/media_file.dart';
import '../models/media_folder.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'media_cache.db';
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE media_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        size INTEGER NOT NULL,
        type TEXT NOT NULL,
        duration_ms INTEGER,
        last_modified INTEGER,
        folder_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE media_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        video_count INTEGER NOT NULL DEFAULT 0,
        audio_count INTEGER NOT NULL DEFAULT 0,
        last_scan INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_timestamp INTEGER NOT NULL,
        total_files INTEGER NOT NULL,
        total_folders INTEGER NOT NULL,
        scan_duration_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_media_files_folder_path ON media_files(folder_path);
    ''');

    await db.execute('''
      CREATE INDEX idx_media_files_type ON media_files(type);
    ''');

    await db.execute('''
      CREATE INDEX idx_media_files_last_modified ON media_files(last_modified);
    ''');
  }

  static Future<void> cacheMediaFiles(List<MediaFile> mediaFiles) async {
    final db = await database;
    final batch = db.batch();

    for (final mediaFile in mediaFiles) {
      final now = DateTime.now().millisecondsSinceEpoch;
      batch.insert(
        'media_files',
        {
          'path': mediaFile.path,
          'name': mediaFile.name,
          'size': mediaFile.size,
          'type': mediaFile.type.toString().split('.').last,
          'duration_ms': mediaFile.duration?.inMilliseconds,
          'last_modified': mediaFile.lastModified?.millisecondsSinceEpoch,
          'folder_path': File(mediaFile.path).parent.path,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<void> cacheMediaFolders(List<MediaFolder> mediaFolders) async {
    final db = await database;
    final batch = db.batch();

    for (final folder in mediaFolders) {
      final now = DateTime.now().millisecondsSinceEpoch;
      batch.insert(
        'media_folders',
        {
          'path': folder.path,
          'name': folder.name,
          'video_count': folder.videoCount,
          'audio_count': folder.audioCount,
          'last_scan': now,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<List<MediaFile>> getCachedMediaFiles() async {
    final db = await database;
    final maps = await db.query('media_files', orderBy: 'last_modified DESC');

    return List<MediaFile>.from(maps.map((map) {
      final durationMs = map['duration_ms'] as int?;
      final lastModifiedMs = map['last_modified'] as int?;

      return MediaFile(
        path: map['path'] as String,
        name: map['name'] as String,
        extension: (map['name'] as String).split('.').last.toLowerCase(),
        size: map['size'] as int,
        type: _parseMediaType(map['type'] as String),
        duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
        lastModified: lastModifiedMs != null ? DateTime.fromMillisecondsSinceEpoch(lastModifiedMs) : null,
      );
    }));
  }

  static Future<List<MediaFolder>> getCachedMediaFolders() async {
    final db = await database;
    final maps = await db.query(
      'media_folders',
      orderBy: 'video_count + audio_count DESC',
    );

    final List<MediaFolder> folders = [];

    for (final map in maps) {
      final folderPath = map['path'] as String;
      final folderMediaFiles = await getCachedMediaFilesInFolder(folderPath);

      folders.add(MediaFolder(
        path: folderPath,
        name: map['name'] as String,
        mediaFiles: folderMediaFiles,
        videoCount: map['video_count'] as int,
        audioCount: map['audio_count'] as int,
      ));
    }

    return folders;
  }

  static Future<List<MediaFile>> getCachedMediaFilesInFolder(String folderPath) async {
    final db = await database;
    final maps = await db.query(
      'media_files',
      where: 'folder_path = ?',
      whereArgs: [folderPath],
      orderBy: 'name ASC',
    );

    return List<MediaFile>.from(maps.map((map) {
      final durationMs = map['duration_ms'] as int?;
      final lastModifiedMs = map['last_modified'] as int?;

      return MediaFile(
        path: map['path'] as String,
        name: map['name'] as String,
        extension: (map['name'] as String).split('.').last.toLowerCase(),
        size: map['size'] as int,
        type: _parseMediaType(map['type'] as String),
        duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
        lastModified: lastModifiedMs != null ? DateTime.fromMillisecondsSinceEpoch(lastModifiedMs) : null,
      );
    }));
  }

  static Future<bool> isCacheValid() async {
    final db = await database;
    final result = await db.query(
      'scan_history',
      orderBy: 'scan_timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return false;

    final lastScanTime = result.first['scan_timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    const cacheValidityPeriod = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

    return (now - lastScanTime) < cacheValidityPeriod;
  }

  static Future<bool> shouldIncrementalScan() async {
    final db = await database;
    final result = await db.query(
      'scan_history',
      orderBy: 'scan_timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return false;

    final lastScanTime = result.first['scan_timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    const incrementalScanPeriod = 6 * 60 * 60 * 1000; // 6 hours in milliseconds

    return (now - lastScanTime) > incrementalScanPeriod && (now - lastScanTime) < (24 * 60 * 60 * 1000);
  }

  static Future<List<String>> getKnownFilePaths() async {
    final db = await database;
    final result = await db.query('media_files', columns: ['path']);
    return result.map((row) => row['path'] as String).toList();
  }

  static Future<void> removeDeletedFiles(List<String> existingPaths) async {
    final db = await database;
    final knownPaths = await getKnownFilePaths();
    final deletedPaths = knownPaths.where((path) => !existingPaths.contains(path)).toList();

    if (deletedPaths.isNotEmpty) {
      final batch = db.batch();
      for (final path in deletedPaths) {
        batch.delete('media_files', where: 'path = ?', whereArgs: [path]);
      }
      await batch.commit();
    }
  }

  static Future<void> updateModifiedFiles(List<MediaFile> modifiedFiles) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final mediaFile in modifiedFiles) {
      batch.update(
        'media_files',
        {
          'name': mediaFile.name,
          'size': mediaFile.size,
          'duration_ms': mediaFile.duration?.inMilliseconds,
          'last_modified': mediaFile.lastModified?.millisecondsSinceEpoch,
          'updated_at': now,
        },
        where: 'path = ?',
        whereArgs: [mediaFile.path],
      );
    }

    await batch.commit();
  }

  static Future<void> recordScanHistory(int totalFiles, int totalFolders, int scanDurationMs) async {
    final db = await database;
    await db.insert('scan_history', {
      'scan_timestamp': DateTime.now().millisecondsSinceEpoch,
      'total_files': totalFiles,
      'total_folders': totalFolders,
      'scan_duration_ms': scanDurationMs,
    });
  }

  static Future<void> clearCache() async {
    final db = await database;
    final batch = db.batch();

    batch.delete('media_files');
    batch.delete('media_folders');
    batch.delete('scan_history');

    await batch.commit();
  }

  static Future<bool> fileExistsInCache(String path) async {
    final db = await database;
    final result = await db.query(
      'media_files',
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<void> removeFromCache(String path) async {
    final db = await database;
    await db.delete(
      'media_files',
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  static Future<Map<String, dynamic>> getCacheStats() async {
    final db = await database;

    final fileCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM media_files')
    ) ?? 0;

    final folderCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM media_folders')
    ) ?? 0;

    final videoCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM media_files WHERE type = 'video'")
    ) ?? 0;

    final audioCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM media_files WHERE type = 'audio'")
    ) ?? 0;

    final lastScanResult = await db.query(
      'scan_history',
      orderBy: 'scan_timestamp DESC',
      limit: 1,
    );

    DateTime? lastScanTime;
    if (lastScanResult.isNotEmpty) {
      lastScanTime = DateTime.fromMillisecondsSinceEpoch(
        lastScanResult.first['scan_timestamp'] as int
      );
    }

    return {
      'totalFiles': fileCount,
      'totalFolders': folderCount,
      'videoCount': videoCount,
      'audioCount': audioCount,
      'lastScanTime': lastScanTime,
      'cacheValid': await isCacheValid(),
    };
  }

  static MediaType _parseMediaType(String typeString) {
    switch (typeString) {
      case 'video':
        return MediaType.video;
      case 'audio':
        return MediaType.audio;
      default:
        return MediaType.unknown;
    }
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}