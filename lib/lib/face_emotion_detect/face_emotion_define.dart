import 'package:rxdart/rxdart.dart';

class FaceEmotionDefine {
  static String currentSelectedEmotion = '';
  static bool get hasSelectedEmotion => currentSelectedEmotion.isNotEmpty;

  static final _emotionDatasetCountStream = BehaviorSubject<Map<String, int>>();
  // Map<emotion, trained dataset count>
  static Stream<Map<String, int>> get emotionDatasetCountStream => _emotionDatasetCountStream;
  static Map<String, int>? _currrentEmotionDatasetCount;

  static Future<void> updateEmotionDatasetCount(Map<String, int> motionDatasetCount) async {
    _emotionDatasetCountStream.add(motionDatasetCount);
    _currrentEmotionDatasetCount = motionDatasetCount;
  }

  static void addEmotion(String emotion) {
    if (_currrentEmotionDatasetCount != null && !_currrentEmotionDatasetCount!.containsKey(emotion)) {
      _currrentEmotionDatasetCount![emotion] = 0;
      _emotionDatasetCountStream.add(_currrentEmotionDatasetCount!);
    }
  }

  static void selectEmotion(String emotion) {
    currentSelectedEmotion = emotion;
  }
}
