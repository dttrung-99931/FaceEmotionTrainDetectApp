import 'dart:io';

import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:face_form_detect/utils/face_property_extension.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ml_algo/ml_algo.dart';

import 'package:ml_dataframe/ml_dataframe.dart';

class FaceEmotionDetector {
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
