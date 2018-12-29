import 'dart:isolate';
import 'dart:async';

class IsolateManager{
  final Function _routine;
  ReceivePort _receivePort;
  SendPort _sendPortToIsolate;
  Isolate _isolate;

  IsolateManager(this._routine);


  Future spawn() async {
    _receivePort = new ReceivePort();
    SendPort sendPortToMe = _receivePort.sendPort;
    _isolate = await Isolate.spawn(this._routine, [sendPortToMe]);
    _sendPortToIsolate = await _receivePort.first;
  }

  void kill(){
    _isolate.kill();
  }

  Future postMessage(message) async {
    ReceivePort responsePort = new ReceivePort();
    _sendPortToIsolate.send([message, responsePort.sendPort]);
    final response = await responsePort.first;
    return response;
  }

}
