import 'dart:math';

class Car {

  /// Beschleunigung bei Vollgas (Pixel pro Sekunde²).
  static const double power = 450;

  /// Reibung: Anteil der Geschwindigkeit, der pro Sekunde verloren geht.
  /// Höchsttempo bei Vollgas ergibt sich aus power / friction = 300 px/s.
  static const double friction = 1.5;

  /// Absolute Obergrenze für die Geschwindigkeit (Pixel pro Sekunde).
  static const double speedLimit = 300;

  /// Drehgeschwindigkeit bei vollem Einschlag (Radiant pro Sekunde).
  /// pi = halbe Umdrehung pro Sekunde, also eine volle in 2 Sekunden.
  static const double turnSpeed = pi;

  /// Ab dieser Geschwindigkeit lenkt das Auto voll.
  /// Darunter weniger, im Stand gar nicht.
  static const double fullTurnAtSpeed = 80;

  
  /// Position auf der Strecke (Pixel).
  Point<double> position;

  /// Blickrichtung in Radiant: 0 = nach oben (Norden), pi/2 = nach rechts.
  double heading;

  /// Aktuelle Geschwindigkeit (Pixel pro Sekunde), nie negativ.
  double speed = 0;

  Car({this.position = const Point(0, 0), this.heading = 0});

  /// Einen Zeitschritt rechnen.
  ///
  /// [dt]       vergangene Zeit in Sekunden (z. B. 0.016 bei 60 FPS)
  /// [steering] −1.0 (links) … +1.0 (rechts)
  /// [gas]      0.0 (kein Gas) … 1.0 (Vollgas)
  void update(double dt, double steering, double gas) {
    // 1. Beschleunigen
    speed += gas * power * dt;

    // 2. Reibung: je schneller, desto stärker
    speed -= speed * friction * dt;

    // 3. Begrenzen: nicht rückwärts, nicht zu schnell
    speed = speed.clamp(0.0, speedLimit);

    // 4. Lenken: im Stand gar nicht, ab fullTurnAtSpeed voll
    final turnFactor = (speed / fullTurnAtSpeed).clamp(0.0, 1.0);
    heading += steering * turnSpeed * turnFactor * dt;

    // 5. Bewegen: Weg = Geschwindigkeit · Zeit, in Blickrichtung
    //    heading 0 = nach oben → y wird kleiner (y zeigt nach unten)
    final distance = speed * dt;
    position = Point(
      position.x + sin(heading) * distance,
      position.y - cos(heading) * distance,
    );
  }
}
