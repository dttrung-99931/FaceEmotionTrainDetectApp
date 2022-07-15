import 'dart:async';

import 'package:face_form_detect/screen/face_detect_screen/face_detect_screen.dart';
import 'package:face_form_detect/screen/face_detect_from_file_screen.dart';
import 'package:face_form_detect/global.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      Global.setCurrentHomeTabIndex(_tabController.index);
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Face detect'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Camera'),
                Tab(text: 'Image'),
              ],
            ),
          ),
          body: const TabBarView(children: [
            FaceDetectScreen(),
            FaceDetectFromImageScreen(),
          ]),
        ),
      ),
    );
  }
}
