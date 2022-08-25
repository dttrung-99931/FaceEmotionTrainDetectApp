import 'package:ml_algo/ml_algo.dart';

import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_algo/src/predictor/predictor.dart';

class EmotionKnnClassifier {
  final Predictor classifier;
  final List<String> emotions;
  // Map to count dataset count per emotion
  final Map<String, int> emotionDatasetCountMap;

  EmotionKnnClassifier({
    required this.emotionDatasetCountMap,
    required DataFrame dataframe,
    required String targetColumnName,
    required ClasscifierAlgo classcifierAlgo,
  })  : emotions = emotionDatasetCountMap.keys.toList(),
        classifier = [
          if (classcifierAlgo == ClasscifierAlgo.knn) KnnClassifier(dataframe, targetColumnName, _getK(dataframe)),
          if (classcifierAlgo == ClasscifierAlgo.decisionTree) DecisionTreeClassifier(dataframe, targetColumnName),
          if (classcifierAlgo == ClasscifierAlgo.logistic) LogisticRegressor(dataframe, targetColumnName),
        ].first;

  DataFrame predict(DataFrame toDetect) {
    return classifier.predict(toDetect);
  }

  static int _getK(DataFrame dataframe) {
    /// Detect face emotion by knn classifier
    // int k = 7;
    // int k = (trainDataFrame.rows.length / emotions.length * 0.3).toInt();
    // k = min(max(k, 1), trainDataFrame.rows.length);
    int k = 3; // more effective for current train data
    return k;
  }
}

enum ClasscifierAlgo {
  knn,
  decisionTree,
  logistic,
}
