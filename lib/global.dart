import 'dart:async';

import 'package:rxdart/rxdart.dart';

class Global {
  static final _currentHomeTabIndexCtrl = PublishSubject<int>();
  static Stream<int> get currentHomeTabIndex => _currentHomeTabIndexCtrl.stream;
  static void setCurrentHomeTabIndex(int index) => _currentHomeTabIndexCtrl.add(index);
}
