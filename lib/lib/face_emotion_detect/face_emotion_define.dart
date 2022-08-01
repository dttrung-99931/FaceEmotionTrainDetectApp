import 'dart:io';

import 'package:flutter/foundation.dart';

import 'face_emotion_trainer.dart';

class FaceEmotionDefine {
  static String currentSelectedEmotion = '';
  static bool get hasSelectedEmotion => currentSelectedEmotion.isNotEmpty;

  static final ValueNotifier<List<String>?> _currentEmotions = ValueNotifier(null);
  static ValueListenable<List<String>?> get currentEmotions => _currentEmotions;
  static Future<void> loadEmotions() async {
    File trainFile = await FaceEmotionTrainer.getTrainFile();
    if (!await trainFile.exists()) {
      _currentEmotions.value = [];
      return;
    }

    String trainContent = await trainFile.readAsString();
    List<String> lines = trainContent.split('\n');
    _currentEmotions.value = lines
        .sublist(1)
        .where((element) => element.isNotEmpty)
        .map(
          (String dataLine) => dataLine.split(',').last,
        )
        .toSet()
        .toList();
  }

  static void addEmotion(String emotion) {
    List<String> emotions = _currentEmotions.value ?? [];
    emotions.add(emotion);
    _currentEmotions.value = [...emotions];
  }

  static void selectEmotion(String emotion) {
    currentSelectedEmotion = emotion;
  }
}
