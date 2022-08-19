import 'dart:io';

import 'package:face_form_detect/lib/face_emotion_detect/face_emotion_trainer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_extend/share_extend.dart';

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
                        textInputAction: TextInputAction.done,
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
                const SizedBox(width: 8),
                _SaveButton(
                  onPressed: () async {
                    await FaceEmotionTrainer.writeAllTrainFile(_controller.text);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.green[300]),
                  onPressed: _importTrainFile,
                  child: const Text('Import'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.green[300]),
                  onPressed: () async {
                    File trainFile = await FaceEmotionTrainer.getTrainFile();
                    await _shareFile(trainFile.path);
                  },
                  child: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _importTrainFile() async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles();
    // if there's a file selected
    if (fileResult != null) {
      File file = File(fileResult.files.single.path!);
      String content = await file.readAsString();
      _controller.text = content;
    }
  }

  Future<String> _exportTrainFile() async {
    String path = await _genExportFilePath();
    File fileToWrite = File(path);
    String trainContent = await FaceEmotionTrainer.getTrainFileContent();
    await fileToWrite.writeAsString(trainContent);
    return path;
  }

  Future<String> _genExportFilePath() async {
    Directory? storageDir =
        Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationSupportDirectory();
    if (storageDir == null) return '';

    // String downloadDirPath = '/storage/emulated/0/Download';
    DateTime now = DateTime.now();
    String date = '${now.day}-${now.month}-${now.year}_${now.hour}h${now.minute}m${now.second}_';
    return '${storageDir.path}/${date + FaceEmotionTrainer.fileName}';
  }

  Future<void> _shareFile(String path) async {
    await ShareExtend.share(path, 'file');
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
