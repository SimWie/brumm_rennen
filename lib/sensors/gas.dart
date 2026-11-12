import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Liest das Mikrofon und macht daraus einen Gas-Wert von 0.0 bis 1.0.
///
/// Benutzung:
///   final gas = Gas();
///   await gas.start();
///   gas.gasValue.listen((wert) => print(wert));
///   ...
///   await gas.stop();
class Gas {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<double> _controller = StreamController<double>.broadcast();
  StreamSubscription<Uint8List>? _micSubscription;

  /// Hier kommen die Gas-Werte raus (0.0 = kein Gas, 1.0 = Vollgas).
  Stream<double> get gasValue => _controller.stream;

  /// Letzter gemessener Rohpegel, ohne Abzug des Grundrauschens.
  double lastLevel = 0;

  /// Grundrauschen: alles darunter zählt als "still".
  double noiseFloor = 0.02;

  /// Verstärkung: normales Brummen ist nur ca. 0.1–0.3 laut.
  double boost = 4;

  /// Startet das Mikrofon. Gibt false zurück, wenn keine Berechtigung.
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) {
      return false;
    }

    final audioStream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));

    _micSubscription = audioStream.listen((bytes) {
      lastLevel = _volume(bytes);
      final gas = (lastLevel - noiseFloor) * boost;
      _controller.add(gas.clamp(0.0, 1.0));
    });

    return true;
  }

  /// Stoppt das Mikrofon.
  Future<void> stop() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    await _recorder.stop();
    _controller.add(0);
  }

  /// Aktuelle Lautstärke als Grundrauschen übernehmen (dabei still sein!).
  void calibrate() {
    noiseFloor = lastLevel;
  }

  /// Aufräumen, wenn die Klasse nicht mehr gebraucht wird.
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _controller.close();
  }

  /// Lautstärke (0.0–1.0) aus den rohen Audio-Bytes berechnen.
  double _volume(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final count = bytes.length ~/ 2; // 2 Bytes pro Sample
    if (count == 0) return 0;

    double sum = 0;
    for (var i = 0; i < count; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768;
      sum += s * s;
    }
    return sqrt(sum / count);
  }
}
