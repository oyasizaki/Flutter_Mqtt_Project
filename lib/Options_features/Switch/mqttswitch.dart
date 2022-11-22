import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/Options_features/Switch/switchappstate.dart';
import 'package:project/Options_features/Switch/switchview.dart';

class mqttswitch extends StatefulWidget {
  const mqttswitch({super.key});

  @override
  State<mqttswitch> createState() => _mqttswitchState();
}

class _mqttswitchState extends State<mqttswitch> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider<MQTTAppState>(
        create: (_) => MQTTAppState(),
        child: SwitchView(),
      ),
    );
  }
}
