import 'package:face_form_detect/global.dart';
import 'package:face_form_detect/screen/train_file_edit_screen.dart';
import 'package:flutter/material.dart';

import 'emotion_detect_train_screen/face_detect_train_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Builder(
          builder: (nestedContext) => Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: const Text('Face detect'),
              centerTitle: true,
              bottom: TabBar(
                controller: DefaultTabController.of(nestedContext),
                tabs: const [
                  Tab(text: 'Train & Test'),
                  Tab(text: 'Train File'),
                ],
              ),
            ),
            body: const TabBarView(children: [
              FaceDetectTrainScreen(),
              TrainFileEditScreen(),
              // EmotionDetectScreen(),
            ]),
          ),
        ),
      );
  }
}
