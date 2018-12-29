import 'package:dartimage/isolate_manager.dart';
import 'package:image/image.dart' as DartImage;
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
    DartImage.Image image = DartImage.Image.fromBytes(width, height, listInt);

    //image = dartImage.gaussianBlur(image, 4);
    image = DartImage.contrast(image, 108.0);
    image = DartImage.brightness(image, 8);

    image = DartImage.fill(image, 0xff00ff);

    List<int> converted = DartImage.encodeJpg(image);

    /***/

    replyTo.send(converted);
  }
}


Future<List<int>> doStuff(List<int> listInt, int width, int height) async {
  IsolateManager imageWorker = new IsolateManager(imageIsolate);
  await imageWorker.spawn();
  List<int> image = await imageWorker.postMessage([listInt, width, height]);
  imageWorker.kill();
  return image;
}


