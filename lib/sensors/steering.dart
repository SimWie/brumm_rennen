import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class Steering {
  // Bereich für den vollen Lenkeinschlag (in Radiant)
  static const double _mostSensitiveAngle = 15 * pi / 180;  // s = 1.0 → voll bei 15°
  static const double _leastSensitiveAngle = 60 * pi / 180; // s = 0.0 → voll bei 60°

  // Lenkwert −1.0 (links) … +1.0 (rechts)
  late final Stream<double> steeringValue =
      accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
          .map((event) => toSteering(atan2(event.y, event.x), _fullLockAngle));

  // Winkel, ab dem voll eingeschlagen wird
  double _fullLockAngle = _leastSensitiveAngle;

  // Empfindlichkeit 0.0 (träge) … 1.0 (direkt)
  double _sensitivity = 0.5;
  double get sensitivity => _sensitivity;

  Steering({double sensitivity = 0.5}) {
    setSteeringSensitivity(sensitivity);
  }

  void setSteeringSensitivity(double s) {
    _sensitivity = s.clamp(0.0, 1.0);
    // Linear zwischen 60° (s = 0) und 15° (s = 1)
    _fullLockAngle = _leastSensitiveAngle -
        _sensitivity * (_leastSensitiveAngle - _mostSensitiveAngle);
  }

  // Reine Mathematik, ohne Sensor → gut testbar
  static double toSteering(double angle, double fullLockAngle) =>
      (angle / fullLockAngle).clamp(-1.0, 1.0);
}