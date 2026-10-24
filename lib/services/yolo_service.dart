import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/yolo_fish_detector.tflite',
      );
      _isModelLoaded = true;
      print("YOLO Model Loaded Successfully!");
    } catch (e) {
      print("Error loading YOLO model: $e");
    }
  }

  Future<List<Map<String, dynamic>>> processFrame(CameraImage image) async {
    if (!_isModelLoaded || _interpreter == null) return [];

    try {
      final img.Image? convertedImage = _convertCameraImage(image);
      if (convertedImage == null) return [];

      final img.Image resizedImage = img.copyResize(
        convertedImage,
        width: 640,
        height: 640,
      );
      final input = _imageToTensor(resizedImage);

      // YOLO output shape for 2 classes: [1, 6, 8400]
      final output = List.filled(1 * 6 * 8400, 0.0).reshape([1, 6, 8400]);

      _interpreter!.run(input, output);

      List<Map<String, dynamic>> detections = [];
      for (int i = 0; i < 8400; i++) {
        // YOLO format: [x, y, w, h, class0_conf, class1_conf]
        double class0Conf = output[0][4][i];
        double class1Conf = output[0][5][i];

        double maxConf = max(class0Conf, class1Conf);

        if (maxConf > 0.5) {
          // 50% threshold
          int classIndex = class0Conf > class1Conf ? 0 : 1;

          detections.add({
            'box': [
              output[0][0][i],
              output[0][1][i],
              output[0][2][i],
              output[0][3][i],
            ],
            'label': classIndex == 0 ? 'Fresh' : 'Stale',
            'confidence': maxConf,
          });
        }
      }
      return detections;
    } catch (e) {
      print("Error during YOLO inference: $e");
      return [];
    }
  }

  List<List<List<List<double>>>> _imageToTensor(img.Image image) {
    final tensor = List.generate(
      1,
      (_) => List.generate(
        640,
        (y) => List.generate(640, (x) {
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
