import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../services/language/app_language.dart';
import '../../theme/app_theme.dart';
import '../../widgets/underwater_background.dart';

// CHANGE THESE 3 to match your own database code.
const String kDbName = 'isdaai.db'; // your database file name
const String kHistoryTable = 'scan_history'; // your scan history table name
const String kImagesFolder =
    'scan_images'; // folder where scan photos are saved

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _loading = true;
  int _scanCount = 0;
  int _dbBytes = 0;
  int _imageBytes = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _dbPath() async => p.join(await getDatabasesPath(), kDbName);

  Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, kImagesFolder));
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    int dbBytes = 0;
    int imageBytes = 0;
    int count = 0;

    final dbFile = File(await _dbPath());
    if (await dbFile.exists()) {
      dbBytes = await dbFile.length();
      try {
        final db = await openDatabase(dbFile.path);
        final rows = await db.rawQuery(
          'SELECT COUNT(*) AS c FROM $kHistoryTable',
        );
        count = (rows.first['c'] as int?) ?? 0;
      } catch (_) {
        count = 0; // table not created yet
      }
    }

    final dir = await _imagesDir();
    if (await dir.exists()) {
      await for (final f in dir.list(recursive: true)) {
        if (f is File) imageBytes += await f.length();
      }
    }

    if (!mounted) return;
    setState(() {
      _dbBytes = dbBytes;
      _imageBytes = imageBytes;
      _scanCount = count;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'All saved scans and their photos will be deleted from this phone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final db = await openDatabase(await _dbPath());
      await db.delete(kHistoryTable);
    } catch (_) {}

    final dir = await _imagesDir();
    if (await dir.exists()) await dir.delete(recursive: true);

    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('History cleared')));
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _row(BuildContext context, IconData icon, String title, String value) {
    final pal = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: pal.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: pal.link.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: pal.link, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: pal.text),
        ),
        trailing: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: pal.text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final total = _dbBytes + _imageBytes;
    final bottomReserved = MediaQuery.paddingOf(context).bottom;

    return UnderwaterBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.tr('set_storage'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomReserved + 20),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: pal.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Used by saved scans',
                          style: TextStyle(color: pal.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmt(total),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: pal.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _row(
                    context,
                    Icons.history_rounded,
                    'Saved scans',
                    '$_scanCount',
                  ),
                  _row(
                    context,
                    Icons.storage_rounded,
                    'Scan history database',
                    _fmt(_dbBytes),
                  ),
                  _row(
                    context,
                    Icons.image_rounded,
                    'Saved fish photos',
                    _fmt(_imageBytes),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _scanCount == 0 && total == 0
                        ? null
                        : _clearHistory,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Clear history'),
                  ),
                ],
              ),
      ),
    );
  }
}
