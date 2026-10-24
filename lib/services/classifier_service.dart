import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

// --- 1. Define the Status Enum ---
enum ScanStatus { ok, notFish, multipleFish, lowConfidence }

// --- 2. Define the Result Class ---
class ClassificationResult {
  final ScanStatus status;
  final String topLabel;
  final String? species;
  final bool isFresh;
  final double freshnessConfidence;
  final double speciesConfidence;

  const ClassificationResult({
    required this.status,
    required this.topLabel,
    this.species,
    this.isFresh = false,
    this.freshnessConfidence = 0,
    this.speciesConfidence = 0,
  });
}

class ClassifierService {
  static const String _modelAsset = 'assets/models/isdaai_14classes.onnx';
  static const String _labelsAsset = 'assets/models/labels.txt';
  static const int _inputSize = 224;

  static const double _rejectThreshold = 0.5;
  static const double _minFreshnessConfidence = 0.6;

  OrtSession? _session;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  String? _loadError;

  Future<void> loadModel() async {
    try {
      // 1. Initialize ONNX Runtime
      final ort = OnnxRuntime();

      // 2. Load the model from assets
      _session = await ort.createSessionFromAsset(_modelAsset);

      // 3. Load labels
      final raw = await rootBundle.loadString(_labelsAsset);
      _labels = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isModelLoaded = true;
      print("ONNX Model loaded successfully! Classes: $_labels");
    } catch (e) {
      _loadError = e.toString();
      print("Error loading ONNX model: $e");
    }
  }

  bool get isModelLoaded => _isModelLoaded;
  String? get loadError => _loadError;

  // --- For Still Photos (Camera) ---
  Future<ClassificationResult?> classifyImage(img.Image image) async {
    if (!_isModelLoaded || _session == null) return null;

    OrtValue? inputTensor;
    Map<String, OrtValue>? outputs;

    try {
      // 1. Resize image to 224x224
      final img.Image resized = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );

      // 2. Convert image to Float32List (raw 0-255 values)
      final inputData = _imageToFloat32List(resized);

      // 3. Create ONNX tensor (shape: [1, 224, 224, 3])
      inputTensor = await OrtValue.fromList(inputData.toList(), [
        1,
        _inputSize,
        _inputSize,
        3,
      ]);

      // 4. Run inference
      outputs = await _session!.run({'input': inputTensor});

      // 5. Get output probabilities (output may be nested like [[...14 values...]])
      final outputList = await outputs.values.first.asList();
      final probs = _flattenToDoubles(outputList);

      if (probs.length != _labels.length) {
        print(
          'Output size (${probs.length}) does not match labels (${_labels.length})',
        );
        return null;
      }

      return _interpret(probs);
    } catch (e, st) {
      print("Error during ONNX inference: $e\n$st");
      return null;
    } finally {
      // Clean up native memory
      try {
        await inputTensor?.dispose();
        if (outputs != null) {
          for (final v in outputs.values) {
            await v.dispose();
          }
        }
      } catch (_) {}
    }
  }

  /// Flattens nested lists (List / Float32List / num) into a flat List<double>.
  List<double> _flattenToDoubles(dynamic data) {
    final result = <double>[];
    void walk(dynamic item) {
      if (item is num) {
        result.add(item.toDouble());
      } else if (item is Iterable) {
        for (final e in item) {
          walk(e);
        }
      }
    }

    walk(data);
    return result;
  }

  Float32List _imageToFloat32List(img.Image image) {
    final Float32List float32List = Float32List(
      1 * _inputSize * _inputSize * 3,
    );
    int index = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        // The model was trained with raw 0-255 pixels (Rescaling layer inside)
        float32List[index++] = pixel.r.toDouble();
        float32List[index++] = pixel.g.toDouble();
        float32List[index++] = pixel.b.toDouble();
      }
    }
    return float32List;
  }

  ClassificationResult _interpret(List<double> probs) {
    double notFish = 0;
    double multiple = 0;
    double pFresh = 0;
    double pStale = 0;
    int topIndex = 0;
    final Map<String, double> speciesProb = {};

    for (var i = 0; i < probs.length; i++) {
      final p = probs[i];
      if (p > probs[topIndex]) topIndex = i;

      final name = _labels[i];
      if (name == 'Not_Fish') {
        notFish = p;
        continue;
      }
      if (name == 'Multiple_Fish') {
        multiple = p;
        continue;
      }

      final cut = name.lastIndexOf('_');
      final sp = cut == -1 ? name : name.substring(0, cut);
      speciesProb[sp] = (speciesProb[sp] ?? 0) + p;

      if (name.endsWith('_Fresh')) {
        pFresh += p;
      } else if (name.endsWith('_Stale')) {
        pStale += p;
      }
    }

    final topLabel = _labels[topIndex];

    // 1) Reject classes first
    if (notFish + multiple >= _rejectThreshold) {
      return ClassificationResult(
        status: multiple > notFish
            ? ScanStatus.multipleFish
            : ScanStatus.notFish,
        topLabel: topLabel,
      );
    }

    // 2) Best species
    String? bestSpecies;
    double bestSpeciesProb = 0;
    speciesProb.forEach((name, p) {
      if (p > bestSpeciesProb) {
        bestSpecies = name;
        bestSpeciesProb = p;
      }
    });

    // 3) Fresh vs Stale
    final fishTotal = pFresh + pStale;
    final isFresh = pFresh >= pStale;
    final freshConf = fishTotal == 0
        ? 0.0
        : (isFresh ? pFresh : pStale) / fishTotal;

    return ClassificationResult(
      status: freshConf < _minFreshnessConfidence
          ? ScanStatus.lowConfidence
          : ScanStatus.ok,
      topLabel: topLabel,
      species: bestSpecies,
      isFresh: isFresh,
      freshnessConfidence: freshConf,
      speciesConfidence: bestSpeciesProb,
    );
  }

  void dispose() {
    _session = null;
  }
}
