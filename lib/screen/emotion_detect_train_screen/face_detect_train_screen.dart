import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_define.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/widgets/hidden_on_event_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../lib/camera.dart';
import '../../lib/face_detect.dart';
import '../../lib/face_emotion_detect/face_emotion_detector.dart';
import '../../widgets/screenshot_on_event_viewer.dart';
import 'defined_emotions_widget.dart';
import '../../widgets/face_detect_painter.dart';

class FaceDetectTrainScreen extends StatefulWidget {
  const FaceDetectTrainScreen({Key? key}) : super(key: key);

  @override
  State<FaceDetectTrainScreen> createState() => _FaceDetectTrainScreenState();
}

class _FaceDetectTrainScreenState extends State<FaceDetectTrainScreen> with WidgetsBindingObserver {
  final _isCamInit = ValueNotifier<bool>(false);
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
    Camera.dispose();
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
    _isCamInit.value = false;
    await Camera.setupCamera();
    await Camera.startImageStream();
    _isCamInit.value = true;
  }

  void _setupDetectingFace() {
    FaceDetect.startDetecting(Camera.imageStream);
    FaceEmotionDetector.startDetecting(FaceDetect.facesStream);
  }

  Future<void> _switchCamera() async {
    Camera.switchCameraDirecttion();
    await Camera.stopImageStream();
    await Camera.dispose();
    await _setup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _isCamInit,
                builder: (_, __) => _isCamInit.value
                    ? Stack(
                        children: [
                          const FaceDetectViewer(),
                          Positioned.fill(
                            bottom: 4,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: _switchCamera,
                                  icon: const Icon(Icons.cameraswitch_outlined, color: Colors.purple),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
            ),
            const DefinedEmotionsWidget(),
            const SizedBox(height: 8),
            Container(
              height: 36,
              width: 128,
              padding: const EdgeInsets.only(bottom: 4.0),
              child: const CatchImageToTrainButton(),
            ),
            SizedBox(height: Platform.isIOS ? 64 : 0),
          ],
        ),
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
            child: Text(snapshot.data ?? false ? 'Back' : 'Train'),
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
        await Camera.pause();
      } else {
        Fluttertoast.showToast(msg: 'No emotion selected');
      }
    }
  }
}

class DetectEmotionButton extends StatelessWidget {
  const DetectEmotionButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _onPressed(),
      child: const Text('Detect'),
    );
  }

  Future<void> _onPressed() async {
    String detected = await FaceEmotionDetector.detect(FaceDetect.currentDetectedFaces!.faces.first);
    Fluttertoast.showToast(msg: detected, gravity: ToastGravity.CENTER);
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
          child: HiddenOnEventWidget(
            isHiddenStream: Camera.isPausedStream,
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
        // Positioned.fill(
        //   child: StreamBuilder<String>(
        //       stream: FaceEmotionDetector.emotionStream,
        //       builder: (context, AsyncSnapshot<String> snapshot) {
        //         return snapshot.hasData
        //             ? Padding(
        //                 padding: const EdgeInsets.all(8.0),
        //                 child: Text(
        //                   'Emotion: ${snapshot.data!}',
        //                   style: const TextStyle(
        //                     color: Colors.white,
        //                     fontWeight: FontWeight.bold,
        //                     fontSize: 16,
        //                   ),
        //                   textAlign: TextAlign.center,
        //                 ),
        //               )
        //             : const SizedBox.shrink();
        //       }),
        // ),
      ],
    );
  }
}
