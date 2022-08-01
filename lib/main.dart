import 'package:flutter/material.dart';

import 'screen/home_screen.dart';

void main() {
  runApp(const FaceFormDetectApp());
}

class FaceFormDetectApp extends StatelessWidget {
  const FaceFormDetectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face form detect',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
