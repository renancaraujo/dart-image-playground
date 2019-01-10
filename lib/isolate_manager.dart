import 'dart:isolate';
import 'dart:async';

class IsolateManager{
  final Function _routine;
  ReceivePort _receivePort;
  Isolate _isolate;

  IsolateManager(this._routine);

  Future postMessage(message) async {
    _receivePort = new ReceivePort();
    SendPort sendPortToMe = _receivePort.sendPort;
    _isolate = await Isolate.spawn(this._routine, [message, sendPortToMe]);
    final response = await _receivePort.first;
    _isolate.kill();
    return response;
  }
}
