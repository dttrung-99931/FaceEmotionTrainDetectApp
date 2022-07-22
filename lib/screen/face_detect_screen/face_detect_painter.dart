import 'dart:developer';
import 'dart:math';
import 'dart:ui';

import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/utils/image_utils.dart';
import 'package:face_form_detect/utils/math_utils.dart';
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
      _drawLandmarks(face, canvas);
      // _drawContours(face, canvas);

      // log(_getFaceAngleInfo(face));
      _drawHeadInfo(face, canvas);
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
    _drawContour(face, canvas, FaceContourType.upperLipTop);
    _drawContour(face, canvas, FaceContourType.upperLipBottom);
    _drawContour(face, canvas, FaceContourType.upperLipBottom);
    _drawContour(face, canvas, FaceContourType.noseBridge);
    _drawContour(face, canvas, FaceContourType.noseBottom);

    _drawContour(face, canvas, FaceContourType.leftEyebrowTop);
    _drawContour(face, canvas, FaceContourType.leftEyebrowBottom);
    _drawContour(face, canvas, FaceContourType.rightEyebrowTop);
    _drawContour(face, canvas, FaceContourType.rightEyebrowBottom);
  }

  void _drawContour(Face face, Canvas canvas, FaceContourType contourType) {
    FaceContour? contour = face.contours[contourType];
    if (contour != null) {
      for (var point in contour.points) {
        _drawPoint(point.x.toDouble(), point.y.toDouble(), canvas);
      }
    }
  }

  void _drawHeadInfo(Face face, Canvas canvas) {
    double y = 8;
    // _drawText(
    //   face: face,
    //   canvas: canvas,
    //   text: 'xyz angles:  ${_getFaceAngleInfo(face)}',
    //   position: Offset(8, y),
    //   // position: Offset(8, y += 16),
    // );
    // _drawText(
    //   face: face,
    //   canvas: canvas,
    //   text: 'Smile:  ${((face.smilingProbability ?? 0) * 100).toStringAsFixed(0)}%',
    //   position: Offset(8, y += 16),
    // );
    // _drawText(
    //   face: face,
    //   canvas: canvas,
    //   text: 'Left eye open:  ${((face.leftEyeOpenProbability ?? 0) * 100).toStringAsFixed(0)}%',
    //   position: Offset(8, y += 16),
    // );
    // _drawText(
    //   face: face,
    //   canvas: canvas,
    //   text: 'Right eye open:  ${((face.smilingProbability ?? 0) * 100).toStringAsFixed(0)}%',
    //   position: Offset(8, y += 16),
    // );

    /// Mouth property

    // Mouth opening value
    FaceContour? upperLipBottom = face.contours[FaceContourType.upperLipBottom];
    FaceContour? lowerLipTop = face.contours[FaceContourType.lowerLipTop];
    double mouthOpeningValue = 0;
    if (upperLipBottom != null && lowerLipTop != null) {
      int pointLenght = upperLipBottom.points.length;
      for (int i = 0; i < pointLenght; i++) {
        mouthOpeningValue += lowerLipTop.points[i].y - upperLipBottom.points[i].y;
      }
      mouthOpeningValue /= pointLenght;
      _drawText(
        face: face,
        canvas: canvas,
        text: 'Mouth opening:  ${mouthOpeningValue.toStringAsFixed(2)}',
        // position: Offset(8, y),
        position: Offset(8, y += 16),
      );
    }

    // Mouth width
    FaceLandmark? leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    FaceLandmark? rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    int mouthWidth = 0;
    if (rightMouth != null && leftMouth != null) {
      mouthWidth = rightMouth.position.x - leftMouth.position.x;
      _drawText(
        face: face,
        canvas: canvas,
        text: 'Mouth width:  $mouthWidth',
        position: Offset(8, y += 16),
      );
    }

    // length from mouth to nose
    FaceLandmark? nose = face.landmarks[FaceLandmarkType.noseBase];
    double lengthFromMouthToNose = 0;
    if (nose != null && rightMouth != null && leftMouth != null) {
      lengthFromMouthToNose = (leftMouth.position.y - nose.position.y + rightMouth.position.y - nose.position.y) / 2;
      _drawText(
        face: face,
        canvas: canvas,
        text: 'Length from mouth to nose:  ${lengthFromMouthToNose.toStringAsFixed(2)}',
        position: Offset(8, y += 16),
      );
    }

    // Angle between left mouth, bottomMouth and right mouth
    FaceLandmark? bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    double angle = 0;
    if (rightMouth != null && leftMouth != null && bottomMouth != null) {
      angle = MathUtils.angleABC(
        leftMouth.position.toOffset(),
        bottomMouth.position.toOffset(),
        rightMouth.position.toOffset(),
      );
      _drawText(
        face: face,
        canvas: canvas,
        text: 'Mouth angle:  ${angle.toStringAsFixed(2)}',
        position: Offset(8, y += 16),
      );
    }
  }

  void _drawText({
    required Face face,
    required Canvas canvas,
    required String text,
    required Offset position,
  }) {
    TextSpan span = TextSpan(
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      text: text,
    );
    TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position);
  }

  String _getFaceAngleInfo(Face face) =>
      '${face.headEulerAngleX?.toStringAsFixed(2)}  |  ${face.headEulerAngleY?.toStringAsFixed(2)}  |  ${face.headEulerAngleZ?.toStringAsFixed(2)}';
}
