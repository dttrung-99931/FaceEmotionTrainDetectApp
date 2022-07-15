import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DetectedFaces {
  final List<Face> faces;
  final InputImage inputImage;

  DetectedFaces(this.faces, this.inputImage);
}
