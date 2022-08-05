import 'dart:async';

import 'package:flutter/material.dart';

/// Widget that screenshot [child] and replace it when received true from [isHiddenStream]
class HiddenOnEventWidget extends StatelessWidget {
  final Widget child;
  final Stream<bool> isHiddenStream;

  const HiddenOnEventWidget({
    required this.child,
    required this.isHiddenStream,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: isHiddenStream,
        builder: (context, AsyncSnapshot<bool?> snapshot) {
          return snapshot.data ?? false ? const SizedBox.shrink() : child;
        });
  }
}
