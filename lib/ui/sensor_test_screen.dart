import 'dart:math';

import 'package:flutter/material.dart';

import '../sensors/gas.dart';
import '../sensors/steering.dart';

/// Testseite: zeigt Lenkung und Gas live an, mit Reglern zum Einstellen.
class SensorTestScreen extends StatefulWidget {
  const SensorTestScreen({super.key});

  @override
  State<SensorTestScreen> createState() => _SensorTestScreenState();
}

class _SensorTestScreenState extends State<SensorTestScreen> {
  final Steering _steering = Steering();
  final Gas _gas = Gas();
  bool _micRunning = false;

  @override
  void dispose() {
    _gas.dispose(); // Mikrofon aus, sonst läuft es weiter
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_micRunning) {
      await _gas.stop();
      setState(() => _micRunning = false);
    } else {
      final ok = await _gas.start();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon-Berechtigung fehlt')),
        );
      }
      setState(() => _micRunning = ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor-Test')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(child: _buildSteering()),
            const VerticalDivider(width: 48),
            Expanded(child: _buildGas()),
          ],
        ),
      ),
    );
  }

  // ---------- Lenkung ----------

  Widget _buildSteering() {
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<double>(
      stream: _steering.steeringValue,
      builder: (context, snapshot) {
        final steer = snapshot.data ?? 0; // −1.0 … +1.0

        return SingleChildScrollView(
          child: Column(
            children: [
              Text('Lenkung', style: textTheme.titleLarge),
              Text(steer.toStringAsFixed(2), style: textTheme.displayMedium),

              // Auto dreht sich mit, max. 45° bei vollem Einschlag
              Transform.rotate(
                angle: steer * pi / 4,
                child: const Icon(Icons.navigation, size: 64),
              ),

              // Balken von −1 (links) bis +1 (rechts), nur Anzeige
              Slider(value: steer, min: -1, max: 1, onChanged: null),

              const SizedBox(height: 8),
              Text('Empfindlichkeit: ${_steering.sensitivity.toStringAsFixed(2)}'),
              Slider(
                value: _steering.sensitivity,
                onChanged: (s) => setState(() => _steering.setSteeringSensitivity(s)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Gas ----------

  Widget _buildGas() {
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<double>(
      stream: _gas.gasValue,
      builder: (context, snapshot) {
        final gas = snapshot.data ?? 0; // 0.0 … 1.0

        return SingleChildScrollView(
          child: Column(
            children: [
              Text('Gas', style: textTheme.titleLarge),
              Text(gas.toStringAsFixed(2), style: textTheme.displayMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: gas, minHeight: 20),
              const SizedBox(height: 8),
              Text('Rohpegel: ${_gas.lastLevel.toStringAsFixed(3)}   '
                  'Rauschen: ${_gas.noiseFloor.toStringAsFixed(3)}'),

              const SizedBox(height: 8),
              Text('Verstärkung: ${_gas.boost.toStringAsFixed(1)}'),
              Slider(
                value: _gas.boost,
                min: 1,
                max: 15,
                onChanged: (b) => setState(() => _gas.boost = b),
              ),

              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _toggleMic,
                    icon: Icon(_micRunning ? Icons.mic_off : Icons.mic),
                    label: Text(_micRunning ? 'Stopp' : 'Mikrofon starten'),
                  ),
                  OutlinedButton(
                    onPressed: _micRunning ? () => setState(_gas.calibrate) : null,
                    child: const Text('Kalibrieren (still sein!)'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
