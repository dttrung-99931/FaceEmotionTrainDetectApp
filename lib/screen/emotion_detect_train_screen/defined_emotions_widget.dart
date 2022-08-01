import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_define.dart';
import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:flutter/material.dart';

class DefinedEmotionsWidget extends StatefulWidget {
  const DefinedEmotionsWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<DefinedEmotionsWidget> createState() => _DefinedEmotionsWidgetState();
}

class _DefinedEmotionsWidgetState extends State<DefinedEmotionsWidget> {
  @override
  void initState() {
    FaceEmotionDefine.loadEmotions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Flexible(
            child: ValueListenableBuilder<List<String>?>(
              valueListenable: FaceEmotionDefine.currentEmotions,
              builder: (BuildContext context, List<String>? emotions, Widget? widget) {
                return emotions != null
                    ? emotions.isNotEmpty
                        ? ListView(
                            scrollDirection: Axis.horizontal,
                            children: emotions
                                .map(
                                  (emotion) => _Emotion(
                                      emotion: emotion,
                                      onPressed: () {
                                        FaceEmotionDefine.selectEmotion(emotion);
                                        setState(() {});
                                      }),
                                )
                                .toList(),
                          )
                        : const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'No defined emotions, press + to add',
                              style: TextStyle(color: Colors.black87),
                            ),
                          )
                    : const CircularProgressIndicator();
              },
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(context: context, builder: (context) => AddEmotionDialog());
            },
            icon: const Icon(Icons.add, size: 16),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}

class _Emotion extends StatelessWidget {
  final void Function() onPressed;
  final String emotion;

  const _Emotion({required this.emotion, required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: FaceEmotionDefine.currentSelectedEmotion == emotion ? Colors.purple : Colors.transparent,
              width: FaceEmotionDefine.currentSelectedEmotion == emotion ? 1 : 0,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Text(emotion)),
    );
  }
}

class AddEmotionDialog extends StatelessWidget {
  AddEmotionDialog({
    Key? key,
  }) : super(key: key);

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add emotion',
              ),
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      FaceEmotionDefine.addEmotion(_controller.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add')),
            ),
          ],
        ),
      ),
    );
  }
}
