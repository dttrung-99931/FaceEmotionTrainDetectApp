import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_define.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/utils/face_property_extension.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ml_algo/ml_algo.dart';

import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:rxdart/rxdart.dart';

class FaceEmotionDetector {
  static final _emotionStream = PublishSubject<String>();
  static final Stream<String> emotionStream = _emotionStream.stream;
  static String currentEmotion = '';
  static StreamSubscription? _faceSubscription;

  static const int _milisDelayDetectAgain = 150;
  static DateTime _lastDetectTime = DateTime.now();

  static EmotionKnnClassifier? _classifier;

  /// Detect emotion of first face from [facesStream]
  /// Stream detected emotion to [emotionStream]
  static void startDetecting(Stream<DetectedFaces> facesStream) async {
    _faceSubscription = facesStream.listen((DetectedFaces faces) async {
      if (!_isNextValidTimeDetect()) return;
      _lastDetectTime = DateTime.now();

      if (faces.faces.isEmpty) return;

      currentEmotion = await detect(faces.faces.first);
      _emotionStream.add(currentEmotion);
    });
  }

  static void stopDetecting() {
    _faceSubscription?.cancel();
  }

  static bool _isNextValidTimeDetect() {
    return DateTime.now().millisecondsSinceEpoch - _lastDetectTime.millisecondsSinceEpoch >= _milisDelayDetectAgain;
  }

  static void markReloading() {
    _classifier = null;
  }

  /// Return detected emotion
  static Future<String> detect(Face emotionFace) async {
    if (_classifier == null) {
      String errorMsg = await setupClassifier();
      if (errorMsg.isNotEmpty) return errorMsg;
    }

    var toDetect = DataFrame([emotionFace.faceProperties], headerExists: false);
    DataFrame results = _classifier!.predict(toDetect);

    /// Return emotion name from detected result
    int? detectedEmotionIndex = results.rows.isNotEmpty ? results.rows.first.last.toInt() : null;
    return detectedEmotionIndex != null ? _classifier!.emotions[detectedEmotionIndex] : 'No detected';
  }

  static Future<String> setupClassifier() async {
    try {
      _classifier ??= await _createKnnClassifier();
      FaceEmotionDefine.updateEmotionDatasetCount(_classifier!.emotionDatasetCountMap);
    } catch (e) {
      return e.toString();
    }
    return '';
  }

  static Future<EmotionKnnClassifier> _createKnnClassifier() async {
    File trainFile = await FaceEmotionTrainer.getTrainFile();
    if (!await trainFile.exists()) {
      throw 'No train file';
    }
    String trainContent = await trainFile.readAsString();
    DataFrame trainDataFrame = DataFrame.fromRawCsv(trainContent);

    if (trainDataFrame.rows.isEmpty) {
      throw 'No train data';
    }

    List<String> trainDatasetLines =
        trainContent.split('\n').sublist(1).where((element) => element.isNotEmpty).toList();
    Map<String, int> emotionDasetCountMap = {};
    for (var line in trainDatasetLines) {
      String emotion = line.split(',').last;
      emotionDasetCountMap[emotion] = (emotionDasetCountMap[emotion] ?? 0) + 1;
    }
    List<String> emotions = emotionDasetCountMap.keys.toList();

    Series emotionNamesColumn = trainDataFrame.series.last;
    trainDataFrame = trainDataFrame.dropSeries(names: [FaceEmotionTrainer.columnFaceEmotion]);
    Series emotionIndexColumn = Series(
      FaceEmotionTrainer.columnFaceEmotion,
      emotionNamesColumn.data.map((e) => emotions.indexOf(e)),
    );
    trainDataFrame = trainDataFrame.addSeries(emotionIndexColumn);

    /// Detect face emotion by knn classifier
    // int k = 7;
    // int k = (trainDataFrame.rows.length / emotions.length * 0.3).toInt();
    // k = min(max(k, 1), trainDataFrame.rows.length);
    int k = 3; // more effective for current train data
    return EmotionKnnClassifier(
      classifier: KnnClassifier(trainDataFrame, FaceEmotionTrainer.columnFaceEmotion, k),
      emotionDatasetCountMap: emotionDasetCountMap,
    );
  }
}

class EmotionKnnClassifier {
  final KnnClassifier classifier;
  final List<String> emotions;
  // Map to count dataset count per emotion
  final Map<String, int> emotionDatasetCountMap;

  EmotionKnnClassifier({required this.classifier, required this.emotionDatasetCountMap})
      : emotions = emotionDatasetCountMap.keys.toList();

  DataFrame predict(DataFrame toDetect) {
    return classifier.predict(toDetect);
  }
}
