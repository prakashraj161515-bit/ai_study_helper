import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> recognizeText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    String text = recognizedText.text;
    _textRecognizer.close();
    
    return text;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
