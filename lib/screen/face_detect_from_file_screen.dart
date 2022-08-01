import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:face_form_detect/lib/camera.dart';
import 'package:face_form_detect/lib/face_detect.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/widgets/face_detect_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';

class FaceDetectFromImageScreen extends StatefulWidget {
  const FaceDetectFromImageScreen({Key? key}) : super(key: key);

  @override
  State<FaceDetectFromImageScreen> createState() => _FaceDetectFromImageScreenState();
}

class _FaceDetectFromImageScreenState extends State<FaceDetectFromImageScreen> {
  Uint8List? _pickedImage;
  DetectedFaces? _detectedFaces;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              _pickedImage != null ? _buildDetectImageResult() : const SizedBox.shrink(),
              ElevatedButton(
                onPressed: _onPickImagePressed,
                child: const Text('Pick image'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stack _buildDetectImageResult() {
    return Stack(
      children: [
        Image.memory(_pickedImage!),
        Positioned.fill(
          child: _detectedFaces != null
              ? CustomPaint(
                  painter: FaceDetectPainter(
                    detectedFaces: _detectedFaces!,
                    imageRotation: InputImageRotation.rotation0deg,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        _pickedImage != null && _detectedFaces == null
            ? const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  void _onPickImagePressed() async {
    XFile? imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      _pickedImage = await imageFile.readAsBytes();
      setState(() {
        _detectedFaces = null;
      });

      List<Face> faces = await FaceDetect.detectFaces(InputImage.fromFile(File(imageFile.path)));
      log(faces.length.toString());

      var image = await decodeImageFromList(_pickedImage!);
      Size size = Size(image.width.toDouble(), image.height.toDouble());

      var inputImageData = InputImageData(
        size: size,
        imageRotation: InputImageRotation.rotation0deg,
        inputImageFormat: InputImageFormat.nv21,
        planeData: [],
      );
      _detectedFaces = DetectedFaces(faces, InputImage.fromBytes(bytes: _pickedImage!, inputImageData: inputImageData));
      setState(() {});
    }
  }
}
