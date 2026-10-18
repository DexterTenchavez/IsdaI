import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/isdaai_mobilenetv2.tflite',
      );
      _isModelLoaded = true;
      print("Model loaded successfully!");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  // --- For Still Photos ---
  Future<Map<String, dynamic>?> classifyImage(img.Image image) async {
    if (!_isModelLoaded || _interpreter == null) return null;

    try {
      final img.Image resized = img.copyResize(image, width: 224, height: 224);

      // FIX: Create a 4D tensor [1, 224, 224, 3]
      final input = _imageToTensor(resized);
      final output = List.filled(1, 0.0).reshape([1, 1]);

      _interpreter!.run(input, output);

      final prediction = output[0][0] as double;
      final isFresh = prediction <= 0.5;
      final confidence = isFresh ? (1 - prediction) : prediction;

      return {'label': isFresh ? 'Fresh' : 'Stale', 'confidence': confidence};
    } catch (e) {
      print("Error during inference: $e");
      return null;
    }
  }

  // --- For Live Camera Stream ---
  Future<Map<String, dynamic>?> classifyCameraImage(CameraImage image) async {
    if (!_isModelLoaded || _interpreter == null) return null;

    try {
      final img.Image? convertedImage = _convertCameraImage(image);
      if (convertedImage == null) return null;

      final img.Image resizedImage = img.copyResize(
        convertedImage,
        width: 224,
        height: 224,
      );
      final input = _imageToTensor(resizedImage);
      final output = List.filled(1, 0.0).reshape([1, 1]);

      _interpreter!.run(input, output);

      final prediction = output[0][0] as double;
      final isFresh = prediction <= 0.5;
      final confidence = isFresh ? (1 - prediction) : prediction;

      return {'label': isFresh ? 'Fresh' : 'Stale', 'confidence': confidence};
    } catch (e) {
      print("Error during inference: $e");
      return null;
    }
  }

  // FIX: This now returns a properly shaped 4D tensor
  List<List<List<List<double>>>> _imageToTensor(img.Image image) {
    final tensor = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );
    return tensor;
  }

  img.Image? _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToImage(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToImage(image);
    }
    return null;
  }

  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final image = img.Image(width: width, height: height);

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final int uvIndex = uvPixelStride * (w ~/ 2) + uvRowStride * (h ~/ 2);
        final int yIndex = cameraImage.planes[0].bytesPerRow * h + w;

        final int y = cameraImage.planes[0].bytes[yIndex];
        final int u = cameraImage.planes[1].bytes[uvIndex];
        final int v = cameraImage.planes[2].bytes[uvIndex];

        final r = (y + 1.402 * (v - 128)).clamp(0, 255).toInt();
        final g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
            .clamp(0, 255)
            .toInt();
        final b = (y + 1.772 * (u - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(w, h, r, g, b);
      }
    }
    return image;
  }

  img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}
