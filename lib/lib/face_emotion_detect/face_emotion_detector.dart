import 'dart:async';
import 'dart:io';

import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_define.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/utils/face_property_extension.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:rxdart/rxdart.dart';

import 'emotion_classifier.dart';

class FaceEmotionDetector {
  static final _emotionStream = PublishSubject<String>();
  static final Stream<String> emotionStream = _emotionStream.stream;
  static String currentDetectedEmotion = '';
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

      currentDetectedEmotion = await detect(faces.faces.first);
      _emotionStream.add(currentDetectedEmotion);
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
    DataFrame detects = _classifier!.predict(toDetect);

    /// Return emotion name from detected dataframe result
    int? detectedEmotionIndex = detects.rows.isNotEmpty ? detects.rows.first.last.toInt() : null;
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
    List<String> trainDatasetLines = trainContent
        .split('\n')
        .sublist(1)
        .where(
          (element) => element.isNotEmpty,
        )
        .toList();

    if (trainDatasetLines.length <= 1) {
      throw 'No train data';
    }

    Map<String, int> emotionDasetCountMap = _createEmotionDatasetMapCount(trainDatasetLines);

    List<String> emotions = emotionDasetCountMap.keys.toList();

    DataFrame trainDataFrame = _createTrainDataFrame(emotions, trainContent);

    return EmotionKnnClassifier(
      dataframe: trainDataFrame,
      targetColumnName: FaceEmotionTrainer.columnFaceEmotion,
      emotionDatasetCountMap: emotionDasetCountMap,
      classcifierAlgo: ClasscifierAlgo.knn,
    );
  }

  /// Return map<emotion, csv dataset line count>
  static Map<String, int> _createEmotionDatasetMapCount(List<String> trainDatasetLines) {
    Map<String, int> emotionDasetCountMap = {};
    for (var line in trainDatasetLines) {
      String emotion = line.split(',').last;
      emotionDasetCountMap[emotion] = (emotionDasetCountMap[emotion] ?? 0) + 1;
    }
    return emotionDasetCountMap;
  }

  /// Create dataframe (like matrix) containing train data rows
  static DataFrame _createTrainDataFrame(List<String> emotions, String trainContent) {
    DataFrame trainDataFrame = DataFrame.fromRawCsv(trainContent);
    Series emotionNamesColumn = trainDataFrame.series.last;
    trainDataFrame = trainDataFrame.dropSeries(names: [FaceEmotionTrainer.columnFaceEmotion]);
    Series emotionIndexColumn = Series(
      FaceEmotionTrainer.columnFaceEmotion,
      emotionNamesColumn.data.map((e) => emotions.indexOf(e)),
    );
    trainDataFrame = trainDataFrame.addSeries(emotionIndexColumn);
    return trainDataFrame;
  }
}
