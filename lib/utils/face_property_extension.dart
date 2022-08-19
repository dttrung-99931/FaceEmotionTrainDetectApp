import 'dart:math';

import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:face_form_detect/utils/math_utils.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

extension FaceProperty on Face {
  double get mouthOpeningValue {
    FaceContour? upperLipBottom = contours[FaceContourType.upperLipBottom];
    FaceContour? lowerLipTop = contours[FaceContourType.lowerLipTop];
    double mouthOpeningValue = 0;
    if (upperLipBottom != null && lowerLipTop != null) {
      int pointLenght = upperLipBottom.points.length;
      for (int i = 0; i < pointLenght; i++) {
        mouthOpeningValue += lowerLipTop.points[i].y - upperLipBottom.points[i].y;
      }
      mouthOpeningValue /= pointLenght;
    }
    return FaceEmotionTrainer.toFaceHeightPercents(mouthOpeningValue, boundingBox.size);
  }

  double get mouthWidth {
    FaceLandmark? leftMouth = landmarks[FaceLandmarkType.leftMouth];
    FaceLandmark? rightMouth = landmarks[FaceLandmarkType.rightMouth];
    double mouthWidth = 0;
    if (rightMouth != null && leftMouth != null) {
      mouthWidth = (rightMouth.position.x - leftMouth.position.x).toDouble();
    }
    return FaceEmotionTrainer.toFaceWidthPercents(mouthWidth, boundingBox.size);
  }

  double get lengthFromMouthToNose {
    FaceLandmark? leftMouth = landmarks[FaceLandmarkType.leftMouth];
    FaceLandmark? rightMouth = landmarks[FaceLandmarkType.rightMouth];
    FaceLandmark? nose = landmarks[FaceLandmarkType.noseBase];
    double lengthFromMouthToNose = 0;
    if (nose != null && rightMouth != null && leftMouth != null) {
      lengthFromMouthToNose = (leftMouth.position.y - nose.position.y + rightMouth.position.y - nose.position.y) / 2;
    }
    return FaceEmotionTrainer.toFaceHeightPercents(lengthFromMouthToNose, boundingBox.size);
  }

  double get lengthEyebrowsToEyes {
    FaceContour? leftEyebrowTop = contours[FaceContourType.leftEyebrowTop];
    FaceContour? rightEyebrowTop = contours[FaceContourType.rightEyebrowTop];
    FaceLandmark? nose = landmarks[FaceLandmarkType.noseBase];
    double length = 0;
    if (nose != null && leftEyebrowTop != null && rightEyebrowTop != null) {
      double totalLength = [...leftEyebrowTop.points, ...rightEyebrowTop.points]
          .fold<double>(0, (previousValue, element) => previousValue + nose.position.y - element.y);
      length = totalLength / (leftEyebrowTop.points.length + rightEyebrowTop.points.length);
    }
    return FaceEmotionTrainer.toFaceHeightPercents(length, boundingBox.size);
  }

  /// Angle between left mouth, bottom mouth and bottom mouth
  double get mouthAngle {
    FaceLandmark? leftMouth = landmarks[FaceLandmarkType.leftMouth];
    FaceLandmark? rightMouth = landmarks[FaceLandmarkType.rightMouth];
    FaceLandmark? bottomMouth = landmarks[FaceLandmarkType.bottomMouth];
    double angle = 0;
    if (rightMouth != null && leftMouth != null && bottomMouth != null) {
      angle = MathUtils.angleABC(
        leftMouth.position.toOffset(),
        bottomMouth.position.toOffset(),
        rightMouth.position.toOffset(),
      );
    }
    return angle;
  }

  /// Length from left check to right check landmarks
  double get cheekWidth {
    FaceLandmark? leftCheek = landmarks[FaceLandmarkType.leftCheek];
    FaceLandmark? rightCheek = landmarks[FaceLandmarkType.rightCheek];
    double width = 0;
    if (leftCheek != null && rightCheek != null) {
      width = (rightCheek.position.x - leftCheek.position.x).toDouble();
    }
    return FaceEmotionTrainer.toFaceWidthPercents(width, boundingBox.size);
  }

  /// Length from left check to right check landmarks
  double get lengthFromCheekToEye {
    FaceLandmark? leftCheek = landmarks[FaceLandmarkType.leftCheek];
    FaceLandmark? leftEye = landmarks[FaceLandmarkType.leftEye];
    FaceLandmark? rightCheek = landmarks[FaceLandmarkType.rightCheek];
    FaceLandmark? rightEye = landmarks[FaceLandmarkType.rightEye];

    double length = 0;
    if (leftCheek != null && leftEye != null && rightEye != null && rightCheek != null) {
      length = (leftCheek.position.y - leftEye.position.y + rightCheek.position.y - rightEye.position.y) / 2;
    }
    return FaceEmotionTrainer.toFaceHeightPercents(length, boundingBox.size);
  }

  double get leftEyeOpeningValue =>
      contours[FaceContourType.leftEye] != null ? _getEyeOpeningValue(contours[FaceContourType.leftEye]!) : 0;

  double get rightEyeOpeningValue =>
      contours[FaceContourType.rightEye] != null ? _getEyeOpeningValue(contours[FaceContourType.rightEye]!) : 0;

  double _getEyeOpeningValue(FaceContour eyeContour) {
    double openingValue = 0;
    int length = eyeContour.points.length;
    for (int i = 0; i < length / 2; i++) {
      openingValue += eyeContour.points[length - 1 - i].y - eyeContour.points[i].y;
    }
    openingValue /= length;
    double percents = FaceEmotionTrainer.toFaceHeightPercents(openingValue, boundingBox.size);
    return percents;
  }

  List<double> get faceProperties => [
        mouthOpeningValue,
        mouthWidth,
        lengthFromMouthToNose,
        mouthAngle,
        // (smilingProbability ?? 0) * 100,
        cheekWidth,
        lengthFromCheekToEye,
        // leftEyeOpenProbability ?? 0,
        // rightEyeOpenProbability ?? 0,
        leftEyeOpeningValue,
        rightEyeOpeningValue,
        lengthEyebrowsToEyes
      ];
}
