import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextScannerService {
  final ImagePicker _picker = ImagePicker();

  /// Launches the camera, captures an image, and extracts any text from it.
  Future<String?> scanTextFromCamera() async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.camera);
      if (pickedImage == null) return null;

      final inputImage = InputImage.fromFile(File(pickedImage.path));
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      print("Text scanning failed: $e");
      return null;
    }
  }

  /// Optionally, support picking from gallery too
  Future<String?> scanTextFromGallery() async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return null;

      final inputImage = InputImage.fromFile(File(pickedImage.path));
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      print("Text scanning from gallery failed: $e");
      return null;
    }
  }
}
