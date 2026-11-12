import 'package:brumm_rennen/ui/sensor_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
  ]);

  runApp(const BrummApp());

}


class BrummApp extends StatelessWidget {
  const BrummApp({super.key});

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Brumm-Rennen',
        theme: ThemeData.dark(useMaterial3: true),
        home: const SensorTestScreen(),
      );
    }
  }