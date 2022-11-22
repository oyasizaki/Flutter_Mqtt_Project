import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/Options_features/Gauge/gaugeappstate.dart';
import 'package:project/Options_features/Gauge/gaugemanager.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GaugeView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GaugeViewState();
  }
}

class _GaugeViewState extends State<GaugeView> {
  final TextEditingController _hostTextController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  late MQTTAppState currentAppState;
  late MQTTManager manager;
  bool _isShow = false;

  @override
  void initState() {
    super.initState();

    /*
    _hostTextController.addListener(_printLatestValue);
    _messageTextController.addListener(_printLatestValue);
    _topicTextController.addListener(_printLatestValue);

     */
  }

  @override
  void dispose() {
    _hostTextController.dispose();
    _messageTextController.dispose();
    _topicTextController.dispose();
    super.dispose();
  }

  /*
  _printLatestValue() {
    print("Second text field: ${_hostTextController.text}");
    print("Second text field: ${_messageTextController.text}");
    print("Second text field: ${_topicTextController.text}");
  }

   */

  @override
  Widget build(BuildContext context) {
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    // Keep a reference to the app state.
    currentAppState = appState;
    final Scaffold scaffold = Scaffold(body: _buildColumn());
    return scaffold;
  }

  Widget _buildColumn() {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.red, Colors.blueAccent],
          ),
        ),
        child: Column(
          children: <Widget>[
            Visibility(
                visible: !_isShow,
                child:
                    _buildScrollableTextWith(currentAppState.getHistoryText)),
            Visibility(
              visible: _isShow,
              child: Column(
                children: [
                  _buildConnectionStateText(_prepareStateMessageFrom(
                      currentAppState.getAppConnectionState)),
                  _buildEditableColumn(),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: CircleBorder(),
              ),
              onPressed: () {
                setState(
                  () {
                    _isShow = !_isShow;
                  },
                );
              },
              // child: Text(
              //   _isShow ? 'Back' : 'Edit',
              //   style: TextStyle(fontSize: 20),
              // ),
              child: Icon(
                _isShow ? Icons.hide_source : Icons.edit,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        children: <Widget>[
          Padding(padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10)),
          _buildTextFieldWith(_hostTextController, 'Enter broker address',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          _buildTextFieldWith(
              _topicTextController,
              'Enter a topic to subscribe or listen',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          // _buildPublishMessageRow(), // -----------------------------------------message send box
          const SizedBox(height: 10),
          _buildConnecteButtonFrom(currentAppState.getAppConnectionState)
        ],
      ),
    );
  }

  // Widget _buildPublishMessageRow() {                                         // message send box -----------------
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     children: <Widget>[
  //       Expanded(
  //         child: _buildTextFieldWith(_messageTextController, 'Enter a message',
  //             currentAppState.getAppConnectionState),
  //       ),
  //       _buildSendButtonFrom(currentAppState.getAppConnectionState)
  //     ],
  //   );
  // }

  Widget _buildConnectionStateText(String status) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
              color: Colors.deepOrangeAccent,
              child: Text(status, textAlign: TextAlign.center)),
        ),
      ],
    );
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if (controller == _messageTextController &&
        state == MQTTAppConnectionState.connected) {
      shouldEnable = true;
    } else if ((controller == _hostTextController &&
            state == MQTTAppConnectionState.disconnected) ||
        (controller == _topicTextController &&
            state == MQTTAppConnectionState.disconnected)) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  Widget _buildScrollableTextWith(double text) {
    return SingleChildScrollView(
      child: SizedBox(
        height: 200,
        child: SfRadialGauge(
            // title: const GaugeTitle(
            //     text: 'Speedometer',
            //     textStyle:
            //         TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            axes: <RadialAxis>[
              RadialAxis(minimum: 0, maximum: 150, ranges: <GaugeRange>[
                GaugeRange(
                    startValue: 0,
                    endValue: 50,
                    color: Colors.green,
                    startWidth: 10,
                    endWidth: 10),
                GaugeRange(
                    startValue: 50,
                    endValue: 100,
                    color: Colors.orange,
                    startWidth: 10,
                    endWidth: 10),
                GaugeRange(
                    startValue: 100,
                    endValue: 150,
                    color: Colors.red,
                    startWidth: 10,
                    endWidth: 10)
              ], pointers: <GaugePointer>[
                NeedlePointer(
                  value: text,
                  enableAnimation: true,
                )
              ], annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    widget: Text(
                      '$text',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber),
                      // maxLines: 9,
                    ),
                    angle: 90,
                    positionFactor: 0.5)
              ])
            ]),
      ),
    );
  }

  Widget _buildConnecteButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          // ignore: deprecated_member_use
          child: ElevatedButton(
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.green),
            ),
            onPressed: state == MQTTAppConnectionState.disconnected
                ? _configureAndConnect
                : null,
            child: const Text('Connect'), //
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // ignore: deprecated_member_use
          child: ElevatedButton(
            style: const ButtonStyle(
              backgroundColor:
                  MaterialStatePropertyAll<Color>(Colors.redAccent),
            ),
            onPressed:
                state == MQTTAppConnectionState.connected ? _disconnect : null,
            child: const Text('Disconnect'), //
          ),
        ),
      ],
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    // ignore: deprecated_member_use
    return ElevatedButton(
      style: const ButtonStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.green),
      ),
      child: const Text('Send'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null, //
    );
  }

  // Utility functions
  String _prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        return 'Connected';
      case MQTTAppConnectionState.connecting:
        return 'Connecting';
      case MQTTAppConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  void _configureAndConnect() {
    // ignore: flutter_style_todos
    // ignore: todo
    // TODO: Use UUID
    String osPrefix =
        'nhjhguiouytreqw34567890987654321'; // Needs to change the id for different clients
    if (Platform.isAndroid) {
      osPrefix =
          '0987654321qwertyuioplkjhgfdsazxcv'; // Needs to change the id for different clients
    }
    manager = MQTTManager(
        host: _hostTextController.text,
        topic: _topicTextController.text,
        identifier: osPrefix,
        state: currentAppState);
    manager.initializeMQTTClient();
    manager.connect();
  }

  void _disconnect() {
    manager.disconnect();
  }

  void _publishMessage(String text) {
    String osPrefix = 'U1';
    if (Platform.isAndroid) {
      osPrefix = 'U2';
    }
    final String message = '$osPrefix>$text';
    manager.publish(message);
    _messageTextController.clear();
  }
}
