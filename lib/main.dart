import 'package:flutter/material.dart';

import 'screen/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Depley to fix ' Null check operator used on a null value' error on release
  await Future.delayed(const Duration(milliseconds: 300));
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
