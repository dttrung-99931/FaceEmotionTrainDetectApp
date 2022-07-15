import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../lib/camera.dart';
import '../../lib/face_detect.dart';
import 'face_detect_painter.dart';

class FaceDetectScreen extends StatefulWidget {
  const FaceDetectScreen({Key? key}) : super(key: key);

  @override
  State<FaceDetectScreen> createState() => _FaceDetectScreenState();
}

class _FaceDetectScreenState extends State<FaceDetectScreen> with WidgetsBindingObserver {
  final _isCameraInit = ValueNotifier<bool>(false);
  final _listenCancelers = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _setup();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _cancelListeners();
    Camera.stopImageStream();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log(state.name);
  }

  Future<void> _cancelListeners() async {
    for (var canceler in _listenCancelers) {
      await canceler.cancel();
    }
    _listenCancelers.clear();
  }

  Future<void> _setup() async {
    await _cancelListeners();
    await _setupCamera();
    _setupDetectingFace();
  }

  Future<void> _setupCamera() async {
    await Camera.setupCamera();
    _isCameraInit.value = true;
    Camera.startImageStream();
  }

  void _setupDetectingFace() {
    FaceDetect.startDetecting(Camera.imageStream, Camera.controller.description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _isCameraInit,
        builder: (_, __) => _isCameraInit.value
            ? Stack(
                children: [
                  CameraPreview(Camera.controller),
                  Positioned.fill(
                    child: StreamBuilder(
                      builder: (_, AsyncSnapshot<DetectedFaces> snapshot) => snapshot.hasData
                          ? CustomPaint(
                              painter: FaceDetectPainter(
                                detectedFaces: snapshot.data!,
                                imageRotation: Camera.imageRotation,
                              ),
                            )
                          : const SizedBox.shrink(),
                      stream: FaceDetect.facesStream,
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
