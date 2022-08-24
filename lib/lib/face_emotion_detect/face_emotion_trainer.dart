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
  static const String trainDataForlder = '/storage/emulated/0/emotion-train-data-d-kid';
  static const Size standardFaceSize = Size(72, 72);

  // Train with data from [trainDataForlder]
  // Rewrite all train file
  static Future<void> trainFromFile() async {
    Directory trainFolder = Directory(trainDataForlder);

    File trainFile = await getTrainFile();
    if (await trainFile.exists()) {
      await trainFile.delete();
    }

    int fromImgIndex = 0;
    int toImgIndex = 100;
    // int toImgIndex = 399;

    await for (FileSystemEntity folder in trainFolder.list()) {
      String emotion = folder.path.split('/').last;
      Directory emotionImgFolder = Directory(folder.path);
      int index = -1;
      await for (FileSystemEntity img in emotionImgFolder.list()) {
        index++;
        if (index < fromImgIndex) continue;
        if (index > toImgIndex) break;

        List<Face> faces = await FaceDetect.detectFaces(InputImage.fromFile(File(img.path)));

        if (faces.isEmpty) continue;

        bool success = await train(faces.first, emotion, checkFilePermission: false);
        log('Train $emotion image index $index ${success.toString()}');
      }
    }
    log(trainFolder.toString());
  }

  static Future<bool> train(Face emotionFace, String emotionName, {bool checkFilePermission = true}) async {
    if (checkFilePermission) {
      await PermissionUtils.ensureStoragePermission();
    }

    File trainFile = await getTrainFile();
    if (!await trainFile.exists()) {
      await trainFile.writeAsString('${_getEmotionPropertyHeaderCsvLine()}\n');
    }
    List<double> faceProperties = emotionFace.faceProperties;
    if (faceProperties.any((element) => element == 0)) {
      return false;
    }
    String csvTrainLine = _getEmotionPropertyCsvLine(faceProperties, emotionName);
    await trainFile.writeAsString('$csvTrainLine\n', mode: FileMode.writeOnlyAppend);
    return true;
  }

  static String _getEmotionPropertyCsvLine(List<double> faceProperties, String emotionName) {
    return [...faceProperties.map((e) => e.toStringAsFixed(2)), emotionName].join(',');
  }

  static String _getEmotionPropertyHeaderCsvLine() {
    return [
      'mouthOpeningValue',
      'mouthWidth',
      'lengthFromMouthToNose',
      'mouthAngle',
      'smilingProbability',
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
