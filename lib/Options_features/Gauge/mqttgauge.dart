import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/Options_features/Gauge/gaugeappstate.dart';
import 'package:project/Options_features/Gauge/gaugeview.dart';

class mqttgauge extends StatefulWidget {
  const mqttgauge({super.key});

  @override
  State<mqttgauge> createState() => _mqttgaugeState();
}

class _mqttgaugeState extends State<mqttgauge> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider<MQTTAppState>(
        create: (_) => MQTTAppState(),
        child: GaugeView(),
      ),
    );
  }
}
