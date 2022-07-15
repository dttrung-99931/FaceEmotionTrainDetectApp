import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_form_detect/utils/image_utils.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:rxdart/rxdart.dart';

class Camera {
  static late CameraController _camController;
  static CameraController get controller => _camController;

  static final _imageStreamCtrl = PublishSubject<CameraImage>();
  static Stream<CameraImage> get imageStream => _imageStreamCtrl.stream;
  static bool _isImageStreaming = false;

  static final _imagePlanesStreamCtrl = PublishSubject<Uint8List>();
  static Stream<Uint8List> get imagePlanesStream => _imagePlanesStreamCtrl.stream;

  static InputImageRotation get imageRotation =>
      InputImageRotationValue.fromRawValue(_camController.description.sensorOrientation)!;

  static Future<void> setupCamera() async {
    CameraDescription description = await _getCameraByCamDirection(CameraLensDirection.front);
    _camController = CameraController(description, ResolutionPreset.low);
    await _camController.initialize();
  }

  static void startImageStream() {
    if (!_isImageStreaming) {
      _isImageStreaming = true;
      _camController.startImageStream((CameraImage image) {
        _imageStreamCtrl.add(image);
        _imagePlanesStreamCtrl.add(ImageUtils.concatanatePlanes(image.planes));
      });
    }
  }

  static void stopImageStream() {
    if (_isImageStreaming) {
      _camController.stopImageStream();
      _isImageStreaming = false;
    }
  }

  static Future<CameraDescription> _getCameraByCamDirection(CameraLensDirection direction) async {
    List<CameraDescription> descriptions = await availableCameras();
    return descriptions.firstWhere((element) => element.lensDirection == direction);
  }
}
