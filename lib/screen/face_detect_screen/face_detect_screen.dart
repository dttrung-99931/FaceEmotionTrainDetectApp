import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../lib/camera.dart';
import '../../lib/face_detect.dart';
import '../../widgets/screenshot_on_event_viewer.dart';
import 'defined_emotions_widget.dart';
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
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _isCameraInit,
              builder: (_, __) => _isCameraInit.value
                  ? const FaceDetectViewer()
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),
          const DefinedEmotionsWidget(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: CatchImageToTrainButton(),
          ),
        ],
      ),
    );
  }
}

class CatchImageToTrainButton extends StatefulWidget {
  const CatchImageToTrainButton({
    Key? key,
  }) : super(key: key);

  @override
  State<CatchImageToTrainButton> createState() => _CatchImageToTrainButtonState();
}

class _CatchImageToTrainButtonState extends State<CatchImageToTrainButton> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: Camera.isPausedStream,
        builder: (context, snapshot) {
          return ElevatedButton(
            onPressed: () => _onPressed(snapshot.data ?? false),
            child: Text(snapshot.data ?? false ? 'Back' : 'Catch'),
          );
        });
  }

  Future<void> _onPressed(bool isDetectingPaused) async {
    if (isDetectingPaused) {
      await Camera.resume();
    } else {
      await FaceEmotionTrainer.train(FaceDetect.currentDetectedFaces!.faces.first, 'smile');
      await Camera.pause();
    }
  }
}

class FaceDetectViewer extends StatelessWidget {
  const FaceDetectViewer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          /// FIXME: [ScreenshotOnEventViewer] not working with CameraPreview
          child: ScreenshotOnEventViewer(
            takeScreenshotStream: Camera.isPausedStream,
            child: CameraPreview(Camera.controller),
          ),
        ),
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
    );
  }
}
