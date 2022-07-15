import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ImageUtils {
  static Uint8List concatanatePlanes(List<Plane> planes) {
    final buffer = WriteBuffer();
    for (Plane plane in planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  static double translateX(double x, InputImageRotation rotation, Size displaySize, Size imageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * displaySize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        return displaySize.width - x * displaySize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
      default:
        return x * displaySize.width / imageSize.width;
    }
  }

  static double translateY(double y, InputImageRotation rotation, Size displaySize, Size imageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * displaySize.height / (Platform.isIOS ? imageSize.height : imageSize.width);
      default:
        return y * displaySize.height / imageSize.height;
    }
  }
}
