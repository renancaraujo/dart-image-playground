import 'package:dartimage/isolate_manager.dart';

import 'dart:isolate';


imageIsolate(List initialMessage) async{
  SendPort sendPort = initialMessage[0];

  ReceivePort port = ReceivePort();
  sendPort.send(port.sendPort);
  await for (var msg in port) {
    SendPort replyTo = msg[1];

    /***/

    List<int> listInt = msg[0][0];
    int width = msg[0][1];
    int height = msg[0][2];


    /***/

    replyTo.send(null);
  }
}


Future<List<int>> doStuff(List<int> listInt, int width, int height) async {
  IsolateManager imageWorker = new IsolateManager(imageIsolate);
  await imageWorker.spawn();
  List<int> image = await imageWorker.postMessage([listInt, width, height]);
  imageWorker.kill();
  return image;
}


