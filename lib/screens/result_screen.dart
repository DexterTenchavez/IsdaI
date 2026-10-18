import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final String label;
  final double confidence;

  const ResultScreen({
    super.key,
    required this.label,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final isFresh = label == 'Fresh';
    final color = isFresh ? AppColors.success : AppColors.danger;
    final icon = isFresh ? Icons.check_circle_rounded : Icons.warning_rounded;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 100),
            const SizedBox(height: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}% confidence',
              style: const TextStyle(fontSize: 18, color: AppColors.textMuted),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                "Scan Again",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
