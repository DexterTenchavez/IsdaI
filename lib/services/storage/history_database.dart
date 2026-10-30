import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/scan_record.dart';
import '../ai/classifier_service.dart';

/// Local scan history (SRS FR-21 to FR-26). Everything stays on the device:
/// results go in a SQLite table, photos are copied into the app's own folder.
class HistoryDatabase {
  HistoryDatabase._();
  static final HistoryDatabase instance = HistoryDatabase._();

  static const String _table = 'scans';

  Future<Database>? _opening;

  Future<Database> get _database => _opening ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/isdaai_history.db',
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_path TEXT,
          species TEXT,
          is_fresh INTEGER NOT NULL,
          freshness_confidence REAL NOT NULL,
          species_confidence REAL NOT NULL,
          top_label TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      '''),
    );
  }

  /// Saves a classified scan. Returns the saved record.
  Future<ScanRecord> saveScan({
    required ClassificationResult result,
    String? imagePath,
  }) async {
    final db = await _database;
    final now = DateTime.now();
    final keptPath = await _keepImage(imagePath, now.millisecondsSinceEpoch);

    final values = <String, Object?>{
      'image_path': keptPath,
      'species': result.species,
      'is_fresh': result.isFresh ? 1 : 0,
      'freshness_confidence': result.freshnessConfidence,
      'species_confidence': result.speciesConfidence,
      'top_label': result.topLabel,
      'created_at': now.millisecondsSinceEpoch,
    };
    final id = await db.insert(_table, values);
    return ScanRecord.fromMap({...values, 'id': id});
  }

  /// All saved scans, newest first.
  Future<List<ScanRecord>> getAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(ScanRecord.fromMap).toList();
  }

  /// Deletes the given scans and their photos.
  Future<void> deleteMany(Iterable<int> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final db = await _database;

    // SQLite limits how many ? marks one query can have, so work in chunks.
    for (var i = 0; i < list.length; i += 400) {
      final chunk = list.sublist(
        i,
        i + 400 > list.length ? list.length : i + 400,
      );
      final marks = List.filled(chunk.length, '?').join(',');

      final rows = await db.query(
        _table,
        columns: ['image_path'],
        where: 'id IN ($marks)',
        whereArgs: chunk,
      );
      await db.delete(_table, where: 'id IN ($marks)', whereArgs: chunk);
      for (final r in rows) {
        await _deleteFile(r['image_path'] as String?);
      }
    }
  }

  /// Removes every saved scan and photo.
  Future<void> clearAll() async {
    final db = await _database;
    final rows = await db.query(_table, columns: ['image_path']);
    await db.delete(_table);
    for (final r in rows) {
      await _deleteFile(r['image_path'] as String?);
    }
  }

  // --- photo helpers -------------------------------------------------------

  /// Camera and gallery photos live in temporary folders the system can
  /// clear, so keep our own copy for the history.
  Future<String?> _keepImage(String? sourcePath, int stamp) async {
    if (sourcePath == null) return null;
    try {
      final src = File(sourcePath);
      if (!await src.exists()) return null;

      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/scan_images');
      if (!await folder.exists()) await folder.create(recursive: true);

      final dot = sourcePath.lastIndexOf('.');
      final slash = sourcePath.lastIndexOf('/');
      final ext = (dot == -1 || dot < slash)
          ? '.jpg'
          : sourcePath.substring(dot);

      final dest = '${folder.path}/scan_$stamp$ext';
      await src.copy(dest);
      return dest;
    } catch (e) {
      debugPrint('Could not copy scan image: $e');
      return null;
    }
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('Could not delete scan image: $e');
    }
  }
}
