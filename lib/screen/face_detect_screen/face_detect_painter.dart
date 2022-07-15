import 'dart:developer';
import 'dart:ui';

import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectPainter extends CustomPainter {
  final DetectedFaces detectedFaces;
  final Paint _boxPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  final Paint _pointPaint = Paint()..color = Colors.green;

  final InputImageRotation imageRotation;
  late final Size imageSize;
  late Size drawSize;

  FaceDetectPainter({
    required this.detectedFaces,
    required this.imageRotation,
  }) : imageSize = detectedFaces.inputImage.inputImageData!.size;

  @override
  void paint(Canvas canvas, Size size) {
    drawSize = size;
    for (var face in detectedFaces.faces) {
      _drawFaceBox(face, canvas);
      // _drawLandmarks(face, canvas);
      _drawContours(face, canvas);
    }
  }

  void _drawFaceBox(Face face, Canvas canvas) {
    Rect box = face.boundingBox;
    Rect translatedBox = Rect.fromLTRB(
      ImageUtils.translateX(box.left, imageRotation, drawSize, imageSize),
      ImageUtils.translateY(box.top, imageRotation, drawSize, imageSize),
      ImageUtils.translateX(box.right, imageRotation, drawSize, imageSize),
      ImageUtils.translateY(box.bottom, imageRotation, drawSize, imageSize),
    );
    canvas.drawRect(translatedBox, _boxPaint);
  }

  void _drawLandmarks(Face face, Canvas canvas) {
    for (var entry in face.landmarks.entries) {
      _drawPoint(entry.value!.position.x.toDouble(), entry.value!.position.y.toDouble(), canvas);
    }
  }

  void _drawPoint(double xOnImage, double yOnImage, Canvas canvas) {
    double translatedX = ImageUtils.translateX(
      xOnImage,
      imageRotation,
      drawSize,
      imageSize,
    );
    double translatedY = ImageUtils.translateY(
      yOnImage,
      imageRotation,
      drawSize,
      imageSize,
    );
    canvas.drawCircle(Offset(translatedX, translatedY), 2, _pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void _drawContours(Face face, Canvas canvas) {
    _drawContour(face, canvas, FaceContourType.face);
    _drawContour(face, canvas, FaceContourType.leftEye);
    _drawContour(face, canvas, FaceContourType.rightEye);
    _drawContour(face, canvas, FaceContourType.lowerLipBottom);
    _drawContour(face, canvas, FaceContourType.lowerLipTop);
  }

  void _drawContour(Face face, Canvas canvas, FaceContourType contourType) {
    FaceContour? contour = face.contours[contourType];
    if (contour != null) {
      for (var point in contour.points) {
        _drawPoint(point.x.toDouble(), point.y.toDouble(), canvas);
      }
    }
  }
}
