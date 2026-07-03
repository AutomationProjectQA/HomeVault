import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text extraction. ML Kit runs on Android/iOS only; elsewhere
/// [isSupported] is false and the scan flow degrades to attach-without-OCR.
abstract interface class OcrService {
  bool get isSupported;
  Future<String?> extractText(String imagePath);
}

class MlKitOcrService implements OcrService {
  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<String?> extractText(String imagePath) async {
    if (!isSupported) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text.isEmpty ? null : result.text;
    } catch (_) {
      return null; // OCR is best-effort; manual entry always available
    } finally {
      await recognizer.close();
    }
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  return MlKitOcrService();
});
