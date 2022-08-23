import 'dart:developer';
import 'dart:io';

import 'package:face_form_detect/utils/face_property_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/permission_utils.dart';
import '../face_detect.dart';

class FaceEmotionTrainer {
  static const String columnFaceEmotion = 'emotionName';
  static const String fileName = 'emotion-face-train-data.csv';
  static const String trainDataForlder = '/storage/emulated/0/emotion-train-data';
  static const Size standardFaceSize = Size(72, 72);

  // Train with data from [trainDataForlder]
  // Rewrite all train file
  static Future<void> trainFromFile({int imagesNumTrainPerEmotion = 2}) async {
    Directory trainFolder = Directory(trainDataForlder);

    await for (FileSystemEntity folder in trainFolder.list()) {
      String emotion = folder.path.split('/').last;
      Directory emotionImgFolder = Directory(folder.path);
      int count = 0;
      await for (FileSystemEntity img in emotionImgFolder.list()) {
        if (count >= 200) continue;

        List<Face> faces = await FaceDetect.detectFaces(InputImage.fromFile(File(img.path)));

        if (faces.isEmpty) continue;

        count++;
        await train(faces.first, emotion, checkFilePermission: false);
        log('Train $emotion $count image');
      }
    }
    log(trainFolder.toString());
  }

  static Future<void> train(Face emotionFace, String emotionName, {bool checkFilePermission = true}) async {
    if (checkFilePermission) {
      await PermissionUtils.ensureStoragePermission();
    }

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
      // 'smilingProbability',
      'cheekWidth',
      'lengthFromCheekToEye',
      // 'leftEyeOpenProbability',
      // 'rightEyeOpenProbability',
      'leftEyeOpeningValue',
      'rightEyeOpeningValue',
      'lengthFromEyebrowsToNose',
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

  static double toFaceWidthPercents(double value, Size faceSize) {
    return value / faceSize.width * 100;
  }

  static double toFaceHeightPercents(double value, Size faceSize) {
    return value / faceSize.height * 100;
  }
}
