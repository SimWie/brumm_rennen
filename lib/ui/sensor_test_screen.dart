import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorTestScreen extends StatefulWidget {
  const SensorTestScreen({super.key});

  @override
  State<SensorTestScreen> createState() => _SensorTestScreenState();
}

class _SensorTestScreenState extends State<SensorTestScreen> {
  final Stream<AccelerometerEvent> _accelStream =
      accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor-Test')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(child: _buildTilt()),
            const SizedBox(width: 24),
            Expanded(child: _buildMic()),
          ],
        ),
      ),
    );
  }

  Widget _buildTilt() {
    return StreamBuilder<AccelerometerEvent>(
      stream: _accelStream,
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: Text('Warte auf Sensor …'));
        }
        
        final e = snapshot.data!;
        final angleDeg = atan2(e.y, e.x) * 180 / pi;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Transform.rotate(
              angle: -angleDeg * pi / 180,
              child: const Icon(Icons.directions_car, size: 80),
            ),

          ],
        );
      },
    );
  }


  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  double _micLevel = 0;      // 0.0 – 1.0
  bool _micRunning = false;

  Future<void> _startMic() async {
    // Fragt beim ersten Mal den Benutzer um Erlaubnis
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon-Berechtigung fehlt')),
        );
      }
      return;
    }

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits, // rohe Samples, nicht komprimiert
      sampleRate: 16000,
      numChannels: 1,                  // Mono reicht
    ));

    _micSub = stream.listen((bytes) {
      setState(() => _micLevel = _rms(bytes));
    });
    setState(() => _micRunning = true);
  }

  Future<void> _stopMic() async {
    await _micSub?.cancel();
    await _recorder.stop();
    setState(() {
      _micRunning = false;
      _micLevel = 0;
    });
  }

  /// Berechnet die Lautstärke (0.0–1.0) aus 16-Bit-PCM-Bytes
  double _rms(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2; // 2 Bytes pro Sample
    if (sampleCount == 0) return 0;

    double sum = 0;
    for (var i = 0; i < sampleCount; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
    }
    return sqrt(sum / sampleCount);
  }

  @override
  void dispose() {
    // WICHTIG: alles aufräumen, sonst läuft das Mikrofon weiter
    _micSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Widget _buildMic() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Gas (Mikrofon)', style: Theme.of(context).textTheme.titleLarge),
        Text(_micLevel.toStringAsFixed(3),
            style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (_micLevel * 5).clamp(0.0, 1.0), // verstärkt, sonst kaum sichtbar
          minHeight: 24,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _micRunning ? _stopMic : _startMic,
          icon: Icon(_micRunning ? Icons.mic_off : Icons.mic),
          label: Text(_micRunning ? 'Stopp' : 'Mikrofon starten'),
        ),
      ],
    );
  }
}