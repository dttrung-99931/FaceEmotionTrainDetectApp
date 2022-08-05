import 'dart:io';

import 'package:face_form_detect/utils/face_property_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/permission_utils.dart';

class FaceEmotionTrainer {
  static const String columnFaceEmotion = 'emotionName';
  static const String fileName = 'emotion-face-train-data.csv';
  static const Size standardFaceSize = Size(72, 72);

  static Future<void> train(Face emotionFace, String emotionName) async {
    await PermissionUtils.ensureStoragePermission();

    File trainFile = await getTrainFile();
    if (!await trainFile.exists()) {
      await trainFile.writeAsString('${_getEmotionPropertyHeaderCsvLine()}\n');
    }
    String csvTrainLine = _getEmotionPropertyCsvLine(emotionFace, emotionName);
    await trainFile.writeAsString('$csvTrainLine\n', mode: FileMode.writeOnlyAppend);
  }

  static String _getEmotionPropertyCsvLine(Face emotionFace, String emotionName) {
    return [...emotionFace.faceProperties.map((e) => e.toStringAsFixed(2)), emotionName].join(',');
  }

  static String _getEmotionPropertyHeaderCsvLine() {
    return [
      'mouthOpeningValue',
      'mouthWidth',
      'lengthFromMouthToNose',
      'mouthAngle',
      columnFaceEmotion,
    ].join(',');
  }

  static Future<String> getTrainFileContent() async {
    File file = await getTrainFile();
    if (!await file.exists()) return '';
    return await file.readAsString();
  }

  static Future<File> getTrainFile() async {
    Directory documentDir = await getApplicationSupportDirectory();
    Directory trainDir = Directory('${documentDir.path}/emotion-face-train-data');
    if (!await trainDir.exists()) {
      await trainDir.create();
    }

    File trainFile = File('${trainDir.path}/$fileName');
    return trainFile;
  }

  static Future<void> writeAllTrainFile(String content) async {
    File file = await getTrainFile();
    await file.writeAsString(content);
  }

  static double standardizeFacePropertyByX(double value, Size faceSize) {
    return value * standardFaceSize.width / faceSize.width;
  }

  static double standardizeFacePropertyByY(double value, Size faceSize) {
    return value * standardFaceSize.height / faceSize.height;
  }
}
