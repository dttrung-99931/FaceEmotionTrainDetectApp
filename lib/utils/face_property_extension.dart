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
    return FaceEmotionTrainer.standardizeFacePropertyByY(mouthOpeningValue, boundingBox.size);
  }

  double get mouthWidth {
    FaceLandmark? leftMouth = landmarks[FaceLandmarkType.leftMouth];
    FaceLandmark? rightMouth = landmarks[FaceLandmarkType.rightMouth];
    double mouthWidth = 0;
    if (rightMouth != null && leftMouth != null) {
      mouthWidth = (rightMouth.position.x - leftMouth.position.x).toDouble();
    }
    return FaceEmotionTrainer.standardizeFacePropertyByX(mouthWidth, boundingBox.size);
  }

  double get lengthFromMouthToNose {
    FaceLandmark? leftMouth = landmarks[FaceLandmarkType.leftMouth];
    FaceLandmark? rightMouth = landmarks[FaceLandmarkType.rightMouth];
    FaceLandmark? nose = landmarks[FaceLandmarkType.noseBase];
    double lengthFromMouthToNose = 0;
    if (nose != null && rightMouth != null && leftMouth != null) {
      lengthFromMouthToNose = (leftMouth.position.y - nose.position.y + rightMouth.position.y - nose.position.y) / 2;
    }
    return FaceEmotionTrainer.standardizeFacePropertyByY(lengthFromMouthToNose, boundingBox.size);
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

  List<double> get faceProperties => [
        mouthOpeningValue,
        mouthWidth,
        lengthFromMouthToNose,
        mouthAngle,
      ];
}
