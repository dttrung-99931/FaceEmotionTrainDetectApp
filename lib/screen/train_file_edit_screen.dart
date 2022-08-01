import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:flutter/material.dart';

class TrainFileEditScreen extends StatefulWidget {
  const TrainFileEditScreen({Key? key}) : super(key: key);

  @override
  State<TrainFileEditScreen> createState() => _TrainFileEditScreenState();
}

class _TrainFileEditScreenState extends State<TrainFileEditScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            FutureBuilder(
              future: FaceEmotionTrainer.getTrainFileContent(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                _controller.text = snapshot.data ?? '';
                return snapshot.hasData
                    ? TextField(
                        controller: _controller,
                        minLines: 20,
                        maxLines: 20,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        scrollPadding: EdgeInsets.zero,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.orange[300]),
                  onPressed: () async {
                    setState(() {});
                  },
                  child: const Text('Reload'),
                ),
                const SizedBox(width: 16),
                _SaveButton(
                  onPressed: () async {
                    await FaceEmotionTrainer.writeAllTrainFile(_controller.text);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const _SaveButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(primary: Colors.green[300]),
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              await widget.onPressed();
              setState(() {
                isLoading = false;
              });
            },
            child: const Text('Save'),
          );
  }
}
