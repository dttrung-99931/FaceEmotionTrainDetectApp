import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:face_form_detect/model/detected_face.dart';
import 'package:face_form_detect/utils/face_property_extension.dart';
import 'package:face_form_detect/utils/math_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/permission_utils.dart';

class FaceEmotionTrainer {
  static const String faceEmotionColName = 'emotionName';

  static Future<void> train(Face emotionFace, String emotionName) async {
    await PermissionUtils.ensureStoragePermission();

    File trainFile = await getTrainFile();
    if (await trainFile.exists()) {
      await trainFile.writeAsString(_getEmotionPropertyHeaderCsvLine());
    }
    String csvTrainLine = _getEmotionPropertyCsvLine(emotionFace, emotionName);
    await trainFile.writeAsString('$csvTrainLine\n');
  }

  static String _getEmotionPropertyCsvLine(Face emotionFace, String emotionName) {
    return [
      emotionFace.mouthOpeningValue.toStringAsFixed(2),
      emotionFace.mouthWidth.toStringAsFixed(2),
      emotionFace.lengthFromMouthToNose.toStringAsFixed(2),
      emotionFace.mouthAngle.toStringAsFixed(2),
      emotionName
    ].join(',');
  }

  static String _getEmotionPropertyHeaderCsvLine() {
    return [
      'mouthOpeningValue',
      'mouthWidth',
      'lengthFromMouthToNose',
      'mouthAngle',
      faceEmotionColName,
    ].join(',');
  }

  static Future<File> getTrainFile() async {
    Directory documentDir = await getApplicationSupportDirectory();
    Directory trainDir = Directory('${documentDir.path}/emotion-face-train-data');
    if (!await trainDir.exists()) {
      await trainDir.create();
    }

    File trainFile = File('${trainDir.path}/emotion-face-train-data.csv');
    return trainFile;
  }
}
