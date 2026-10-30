import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/app_language.dart';
import '../services/date_label.dart';
import '../services/history_database.dart';
import '../theme/app_theme.dart';
import '../widgets/underwater_background.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanRecord>? _records; // null while loading
  final Set<int> _selected = {};
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await HistoryDatabase.instance.getAll();
      if (!mounted) return;
      setState(() {
        _records = rows;
        _selected.retainAll(rows.map((r) => r.id).toSet());
        if (rows.isEmpty) _selecting = false;
      });
    } catch (e) {
      debugPrint('History load error: $e');
      if (!mounted) return;
      setState(() => _records = []);
      _toast('history_load_fail');
    }
  }

  void _toast(String key) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.tr(key))));
  }

  // --- selection -----------------------------------------------------------

  void _exitSelect() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggle(ScanRecord r) {
    setState(() {
      if (!_selected.add(r.id)) _selected.remove(r.id);
    });
  }

  void _startSelect(ScanRecord r) {
    if (_selecting) return;
    setState(() {
      _selecting = true;
      _selected.add(r.id);
    });
  }

  void _toggleSelectAll() {
    final records = _records ?? const <ScanRecord>[];
    setState(() {
      if (_selected.length == records.length) {
        _selected.clear();
      } else {
        _selected.addAll(records.map((r) => r.id));
      }
    });
  }

  // --- delete --------------------------------------------------------------

  Future<bool> _confirm(
    String titleKey,
    String bodyKey,
    String actionKey,
  ) async {
    final pal = context.pal;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(titleKey)),
        content: Text(context.tr(bodyKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.tr(actionKey),
              style: TextStyle(color: pal.bad, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await _confirm(
      'history_delete_title',
      'history_delete_body',
      'history_delete',
    );
    if (!ok) return;

    try {
      await HistoryDatabase.instance.deleteMany(_selected);
    } catch (e) {
      debugPrint('History delete error: $e');
    }
    if (!mounted) return;
    _exitSelect();
    await _load();
  }

  Future<void> _clearAll() async {
    final ok = await _confirm(
      'history_clear_title',
      'history_clear_body',
      'history_clear_all',
    );
    if (!ok) return;

    try {
      await HistoryDatabase.instance.clearAll();
    } catch (e) {
      debugPrint('History clear error: $e');
    }
    if (!mounted) return;
    _exitSelect();
    await _load();
  }

  // --- open ----------------------------------------------------------------

  void _open(ScanRecord r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: r.toResult(),
          imagePath: r.imagePath,
          record: r,
        ),
      ),
    );
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final records = _records;
    final hasRecords = records != null && records.isNotEmpty;
    final allSelected = hasRecords && _selected.length == records.length;

    return PopScope(
      // Back first leaves select mode, then closes the screen.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exitSelect();
      },
      child: UnderwaterBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: _selecting
                ? IconButton(
                    onPressed: _exitSelect,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            title: Text(
              _selecting
                  ? context.tr(
                      'history_selected',
                      args: {'n': '${_selected.length}'},
                    )
                  : context.tr('history_title'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (hasRecords && _selecting) ...[
                IconButton(
                  tooltip: context.tr(
                    allSelected ? 'history_deselect_all' : 'history_select_all',
                  ),
                  onPressed: _toggleSelectAll,
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('history_delete'),
                  onPressed: _selected.isEmpty ? null : _deleteSelected,
                  icon: const Icon(Icons.delete_rounded),
                ),
              ] else if (hasRecords) ...[
                IconButton(
                  tooltip: context.tr('history_select'),
                  onPressed: () => setState(() => _selecting = true),
                  icon: const Icon(Icons.checklist_rounded),
                ),
                IconButton(
                  tooltip: context.tr('history_clear_all'),
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
              ],
            ],
          ),
          body: SafeArea(top: false, child: _body(records)),
        ),
      ),
    );
  }

  Widget _body(List<ScanRecord>? records) {
    if (records == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (records.isEmpty) return _empty();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: records.length,
      itemBuilder: (context, i) {
        final r = records[i];
        return _HistoryCard(
          record: r,
          selecting: _selecting,
          selected: _selected.contains(r.id),
          onTap: () => _selecting ? _toggle(r) : _open(r),
          onLongPress: () => _startSelect(r),
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('history_empty_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('history_empty_body'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanRecord record;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _HistoryCard({
    required this.record,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  static const double _thumbSize = 64;

  Widget _thumb(AppPalette pal) {
    final fallback = Container(
      width: _thumbSize,
      height: _thumbSize,
      color: pal.link.withValues(alpha: 0.12),
      child: Icon(Icons.set_meal_rounded, color: pal.link),
    );

    final path = record.imagePath;
    if (path == null) return fallback;

    return Image.file(
      File(path),
      width: _thumbSize,
      height: _thumbSize,
      fit: BoxFit.cover,
      cacheWidth: 200, // small copy in memory, enough for a thumbnail
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final color = record.isFresh ? pal.good : pal.bad;
    final speciesName = record.speciesConfidence < 0.5
        ? context.tr('species_unclear')
        : (record.species ?? context.tr('species_unknown'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: pal.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: selected
              ? const BorderSide(color: AppColors.accent, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _thumb(pal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        speciesName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pal.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              record.isFresh
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_rounded,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              context.tr(record.isFresh ? 'fresh' : 'stale'),
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scanDateLabel(context, record.createdAt),
                        style: TextStyle(color: pal.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (selecting)
                  Checkbox(
                    value: selected,
                    activeColor: AppColors.accent,
                    onChanged: (_) => onTap(),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: pal.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
