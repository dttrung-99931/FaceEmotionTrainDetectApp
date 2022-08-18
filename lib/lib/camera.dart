import 'dart:async';
import 'dart:io';
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

  static final _isPausedStream = PublishSubject<bool>();
  static Stream<bool> get isPausedStream => _isPausedStream.stream;
  static Future<bool> get isPaused => _isPausedStream.stream.last;

  static CameraLensDirection _camDirection = CameraLensDirection.back;

  static Future<void> setupCamera() async {
    CameraDescription description = await _getCameraByCamDirection(_camDirection);
    _camController = CameraController(
      description,
      ResolutionPreset.low,
      imageFormatGroup: Platform.isAndroid ? null : ImageFormatGroup.bgra8888,
      enableAudio: false,
    );
    await _camController.initialize();
  }

  static Future<void> startImageStream() async {
    if (!_isImageStreaming) {
      await _camController.startImageStream((CameraImage image) {
        _imageStreamCtrl.add(image);
        _imagePlanesStreamCtrl.add(ImageUtils.concatanatePlanes(image.planes));
      });
      _isImageStreaming = true;
    }
  }

  static Future<void> stopImageStream() async {
    if (_isImageStreaming) {
      if (_camController.value.isStreamingImages) {
        await _camController.stopImageStream();
      }
      _isImageStreaming = false;
    }
  }

  static Future<CameraDescription> _getCameraByCamDirection(CameraLensDirection direction) async {
    List<CameraDescription> descriptions = await availableCameras();
    return descriptions.firstWhere((element) => element.lensDirection == direction);
  }

  static Future<void> pause() async {
    await stopImageStream();
    _isPausedStream.add(true);
  }

  static Future<void> resume() async {
    await startImageStream();
    _isPausedStream.add(false);
  }

  static void switchCameraDirecttion() async {
    _camDirection = _camDirection == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
  }

  static Future<void> dispose() async {
    await _camController.dispose();
  }
}
