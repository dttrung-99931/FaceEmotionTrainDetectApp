import 'dart:math';
import 'dart:ui';

class MathUtils {
  // Return ABC angle in degree
  static double angleABC(Offset A, Offset B, Offset C) {
    // AB vector
    var BA = Offset(A.dx - B.dx, A.dy - B.dy);
    var BC = Offset(C.dx - B.dx, C.dy - B.dy);
    double cosABC =
        (BA.dx * BC.dx + BA.dy * BC.dy) / (sqrt(pow(BA.dx, 2) + pow(BA.dy, 2)) * sqrt(pow(BC.dx, 2) + pow(BC.dy, 2)));
    return acos(cosABC) * 180 / pi;
  }
}

extension PointExtension on Point<num> {
  Offset toOffset() {
    return Offset(x.toDouble(), y.toDouble());
  }
}
