import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math';

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
    if (!await trainFile.exists()) {
      return 'No train file';
    }
    String trainContent = await trainFile.readAsString();
    DataFrame trainDataFrame = DataFrame.fromRawCsv(trainContent);

    if (trainDataFrame.rows.isEmpty) return 'No train data';

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
    // int k = 7;
    int k = (trainDataFrame.rows.length / emotions.length * 0.3).toInt();
    k = min(max(k, 1), trainDataFrame.rows.length);
    KnnClassifier classifier = KnnClassifier(trainDataFrame, FaceEmotionTrainer.columnFaceEmotion, k);
    var toDetect = DataFrame([emotionFace.faceProperties], headerExists: false);
    DataFrame results = classifier.predict(toDetect);

    /// Return emotion name from detected result
    int? detectedEmotionIndex = results.rows.isNotEmpty ? results.rows.first.last.toInt() : null;
    return detectedEmotionIndex != null ? emotions[detectedEmotionIndex] : 'No detected';
  }

  static Future<void> _correctTrainFile(File trainFile, String trainContent) async {
    List<String> lines = trainContent.split('\n').where((line) => line.isNotEmpty).toList();
    if (lines.length < 2) return;

    var columnCount = lines[0].split(',').length;
    var valueCount = lines[1].split(',').length;
    bool isDataLineFitHeaderLine = columnCount == valueCount;
    if (isDataLineFitHeaderLine) return; // train file is corret, no need fixing

    int valueCountToAdd = columnCount - valueCount;
    if (valueCountToAdd <= 0) return; // only fix value count != column count, not fix otherwise
    for (int i = 1; i < lines.length; i++) {
      int lastCommaIdx = lines[i].lastIndexOf(',');
      lines[i] += '${',0.00' * valueCountToAdd}\n';
      lines[i] = lines[i].substring(0, lastCommaIdx) + ',0.00' * valueCountToAdd + lines[i].substring(lastCommaIdx);
    }
    String fixed = '${lines.join('\n')}\n';
    await trainFile.writeAsString(fixed);
  }
}
