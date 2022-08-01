import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_define.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:flutter/material.dart';

import '../../lib/camera.dart';
import '../../lib/face_detect.dart';
import '../../widgets/face_detect_painter.dart';
import '../../widgets/screenshot_on_event_viewer.dart';

class EmotionDetectScreen extends StatefulWidget {
  const EmotionDetectScreen({Key? key}) : super(key: key);

  @override
  State<EmotionDetectScreen> createState() => _FaceDetectScreenState();
}

class _FaceDetectScreenState extends State<EmotionDetectScreen> with WidgetsBindingObserver {
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: CatchImageToDetectEmotionButton(),
          ),
        ],
      ),
    );
  }
}

class CatchImageToDetectEmotionButton extends StatefulWidget {
  const CatchImageToDetectEmotionButton({
    Key? key,
  }) : super(key: key);

  @override
  State<CatchImageToDetectEmotionButton> createState() => _CatchImageToDetectEmotionButtonState();
}

class _CatchImageToDetectEmotionButtonState extends State<CatchImageToDetectEmotionButton> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: Camera.isPausedStream,
        builder: (context, snapshot) {
          return ElevatedButton(
            onPressed: () => _onPressed(snapshot.data ?? false),
            child: Text(snapshot.data ?? false ? 'Back' : 'Detect'),
          );
        });
  }

  Future<void> _onPressed(bool isDetectingPaused) async {
    if (isDetectingPaused) {
      await Camera.resume();
    } else {
      if (FaceEmotionDefine.hasSelectedEmotion) {
        await FaceEmotionTrainer.train(
          FaceDetect.currentDetectedFaces!.faces.first,
          FaceEmotionDefine.currentSelectedEmotion,
        );
      }
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
          child: CameraPreview(Camera.controller),
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
