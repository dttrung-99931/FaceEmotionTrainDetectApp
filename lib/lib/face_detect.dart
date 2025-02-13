import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_form_detect/lib/camera.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:rxdart/rxdart.dart';

class FaceDetect {
  static final FaceDetector _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
    enableClassification: true,
    enableLandmarks: true,
    enableContours: true,
    // enableTracking: true,
  ));

  static final _facesStreamCtrl = PublishSubject<DetectedFaces>();

  static Stream<DetectedFaces> get facesStream => _facesStreamCtrl.stream;

  static DetectedFaces? _currentDetectedFaces;
  static DetectedFaces? get currentDetectedFaces => _currentDetectedFaces;

  static StreamSubscription? _streamSubscription;
  static bool _isDetectingImage = false;

  static DateTime _lastDetectTime = DateTime.now();
  static const int _milisDelayDetectAgain = 100;

  static const defaultFaceBoundingBoxSize = 90;

  static Future<List<Face>> detectFaces(InputImage inputImage) async {
    try {
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      log(e.toString());
    }
    return [];
  }

  /// Detect face from image stream
  /// Send detected faces to [facesStream]
  static void startDetecting(Stream<CameraImage> imgStream) {
    _streamSubscription = imgStream.listen((image) async {
      if (_isDetectingImage || !_isNextValidTimeDetect()) return;
      _isDetectingImage = true;
      _lastDetectTime = DateTime.now();

      InputImage inputImage = InputImage.fromBytes(
        bytes: ImageUtils.concatanatePlanes(image.planes),
        inputImageData: _buildInputImageData(
          image,
          InputImageRotationValue.fromRawValue(Camera.controller.description.sensorOrientation)!,
        ),
      );
      List<Face> detected = await detectFaces(inputImage);
      var detectedFaces = DetectedFaces(detected, inputImage);
      if (detected.isNotEmpty) {
        _currentDetectedFaces = detectedFaces;
        log('${detected.length} detected');
      }
      _facesStreamCtrl.add(detectedFaces);
      _isDetectingImage = false;
    });
  }

  static bool _isNextValidTimeDetect() {
    return DateTime.now().millisecondsSinceEpoch - _lastDetectTime.millisecondsSinceEpoch >= _milisDelayDetectAgain;
  }

  static void stopDetecting() {
    _streamSubscription?.cancel();
  }

  static InputImageData _buildInputImageData(CameraImage image, InputImageRotation imageRotation) {
    return InputImageData(
      planeData: image.planes
          .map(
            (Plane plane) =>
                InputImagePlaneMetadata(bytesPerRow: plane.bytesPerRow, height: plane.height, width: plane.width),
          )
          .toList(),
      size: Size(image.width.toDouble(), image.height.toDouble()),
      inputImageFormat: InputImageFormatValue.fromRawValue(image.format.raw)!,
      imageRotation: imageRotation,
    );
  }
}
