import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Widget that screenshot [child] and replace it when received true from [takeScreenshotStream]
class ScreenshotOnEventViewer extends StatefulWidget {
  final Widget child;
  final Stream<bool> takeScreenshotStream;

  const ScreenshotOnEventViewer({
    required this.child,
    required this.takeScreenshotStream,
    Key? key,
  }) : super(key: key);

  @override
  State<ScreenshotOnEventViewer> createState() => _ScreenshotOnEventViewerState();
}

class _ScreenshotOnEventViewerState extends State<ScreenshotOnEventViewer> {
  // final ScreenshotController _key = ScreenshotController();
  final GlobalKey _key = GlobalKey();
  Uint8List? _screenshotImage;

  @override
  void initState() {
    widget.takeScreenshotStream.listen((event) async {
      if (event) {
        _screenshotImage = await _takeScreenshot();
      } else {
        _screenshotImage = null;
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _key,
      child: _screenshotImage != null ? Image.memory(_screenshotImage!) : widget.child,
    );
  }

  Future<Uint8List> _takeScreenshot() async {
    RenderRepaintBoundary boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
