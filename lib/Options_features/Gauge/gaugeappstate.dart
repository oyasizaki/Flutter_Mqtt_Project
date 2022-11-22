// ignore: file_names
import 'package:flutter/cupertino.dart';

enum MQTTAppConnectionState { connected, disconnected, connecting }

class MQTTAppState with ChangeNotifier {
  MQTTAppConnectionState _appConnectionState =
      MQTTAppConnectionState.disconnected;
  // String _receivedText = '';
  // String _historyText = '';

  double _receivedText = 0;
  double _historyText = 0;

  void setReceivedText(String text) {
    // _receivedText = text;

    _receivedText = double.parse(text);

    // _historyText = '$_historyText\n$_receivedText'; // to list the message
    _historyText = _receivedText; // view single and latest message
    // temp = double.parse(text);

    // receivetemp = double.parse(_receivedText);
    // histemp = receivetemp;

    notifyListeners();
  }

  void setAppConnectionState(MQTTAppConnectionState state) {
    _appConnectionState = state;
    notifyListeners();
  }

  // String get getReceivedText => _receivedText;
  // String get getHistoryText => _historyText;

  double get getReceivedText => _receivedText;
  double get getHistoryText => _historyText;
  MQTTAppConnectionState get getAppConnectionState => _appConnectionState;
}
