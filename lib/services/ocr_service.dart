import 'package:image_picker/image_picker.dart';
import 'ai_service.dart';

class OCRService {
  final AIService _ai = AIService();

  Future<String> recognizeText(XFile image) async {
    try {
      // Read image as bytes (Works on Web, Android, iOS)
      final bytes = await image.readAsBytes();
      
      // Use Gemini to process the image and extract text/answer
      return await _ai.processImage(bytes);
    } catch (e) {
      print("OCR Error: $e");
      throw Exception("Failed to process image: $e");
    }
  }

  void dispose() {
    // No native resources to close anymore
  }
}
