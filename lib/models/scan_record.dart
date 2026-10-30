import '../services/classifier_service.dart';

/// One saved scan (a row in the SQLite history table).
class ScanRecord {
  final int id;

  /// Copy of the photo kept inside the app's own storage.
  /// Null if the photo could not be copied.
  final String? imagePath;

  final String? species;
  final bool isFresh;
  final double freshnessConfidence;
  final double speciesConfidence;
  final String topLabel;
  final DateTime createdAt;

  const ScanRecord({
    required this.id,
    required this.imagePath,
    required this.species,
    required this.isFresh,
    required this.freshnessConfidence,
    required this.speciesConfidence,
    required this.topLabel,
    required this.createdAt,
  });

  /// Only classified scans (Fresh or Stale) are saved, so status is always ok.
  ClassificationResult toResult() => ClassificationResult(
    status: ScanStatus.ok,
    topLabel: topLabel,
    species: species,
    isFresh: isFresh,
    freshnessConfidence: freshnessConfidence,
    speciesConfidence: speciesConfidence,
  );

  factory ScanRecord.fromMap(Map<String, Object?> m) => ScanRecord(
    id: m['id'] as int,
    imagePath: m['image_path'] as String?,
    species: m['species'] as String?,
    isFresh: (m['is_fresh'] as int) == 1,
    freshnessConfidence: (m['freshness_confidence'] as num).toDouble(),
    speciesConfidence: (m['species_confidence'] as num).toDouble(),
    topLabel: m['top_label'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}
