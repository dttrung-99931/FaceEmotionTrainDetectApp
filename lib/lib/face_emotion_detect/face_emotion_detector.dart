import 'dart:async';
import 'dart:io';

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

  /// Return detected emotion
  static Future<String> detect(Face emotionFace) async {
    /// Read emotion train file
    File trainFile = await FaceEmotionTrainer.getTrainFile();
    String trainContent = await trainFile.readAsString();
    DataFrame trainDataFrame = DataFrame.fromRawCsv(trainContent);

    /// Replace emotions column by emotions index column to used Knn algo latter
    List<String> emotions = trainContent
        .split('\n')
        .sublist(1)
        .where((element) => element.isNotEmpty)
        .map((e) => e.split(',').last)
        .toSet()
        .toList();
    Series emotionNamesColumn = trainDataFrame.series.last;
    trainDataFrame = trainDataFrame.dropSeries(names: [FaceEmotionTrainer.columnFaceEmotion]);
    Series emotionIndexColumn = Series(
      FaceEmotionTrainer.columnFaceEmotion,
      emotionNamesColumn.data.map((e) => emotions.indexOf(e)),
    );
    trainDataFrame = trainDataFrame.addSeries(emotionIndexColumn);

    /// Detect face emotion by knn classifier
    KnnClassifier classifier = KnnClassifier(trainDataFrame, FaceEmotionTrainer.columnFaceEmotion, 3);
    var toDetect = DataFrame([emotionFace.faceProperties], headerExists: false);
    DataFrame results = classifier.predict(toDetect);

    /// Return emotion name from detected result
    int? detectedEmotionIndex = results.rows.isNotEmpty ? results.rows.first.last.toInt() : null;
    return detectedEmotionIndex != null ? emotions[detectedEmotionIndex] : 'No detected';
  }
}
