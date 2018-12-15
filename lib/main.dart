import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as dartImage;
import 'dart:ui' as ui;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ImageValueNotifier imageValueNotifier = ImageValueNotifier();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imageValueNotifier.loadImage();
  }


  void _transformImage() {
    if(imageValueNotifier.value != null) imageValueNotifier.changeImage();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          imageValueNotifier.reset();
        },
        child: Center(
            child: ValueListenableBuilder(valueListenable: imageValueNotifier ?? ImageValueNotifier(), builder: (BuildContext context, ui.Image value, Widget child){
              if(value == null) return CircularProgressIndicator();
              return RawImage(
                image: value,
              );
            })
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _transformImage,
        tooltip: 'Change image',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}



class ImageValueNotifier extends ValueNotifier<ui.Image>{
  ImageValueNotifier() : super(null);

  ui.Image initial = null;

  void reset() {
    value = initial;
  }

  void loadImage(){
    ImageProvider imageProvider = AssetImage("assets/doggo.jpeg");
    final Completer completer = Completer<ImageInfo>();
    final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
    final listener = (ImageInfo info, bool synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info);
      }
    };
    stream.addListener(listener);
    completer.future.then((info) {
      ImageInfo imageInfo = info as ImageInfo;
      value = imageInfo.image;
      initial = value;
    });
  }

  void changeImage () async {
    ByteData byteData = await value.toByteData();
    List<int> listInt = byteData.buffer.asUint8List();

    ui.Image temp = value;
    value = null;
    List<int> converted = await spawnIsolate(listInt, temp.width, temp.height);
    print("foi 1");
    ui.decodeImageFromList(converted, (image){
      print("foi 2");
      value = image;
    });
  }

}


Future<List<int>> spawnIsolate(List<int> listInt, int width, int height) async {
  ReceivePort receivePort = new ReceivePort();
  SendPort sendPort = receivePort.sendPort;
  Isolate.spawn(insideIsolate, sendPort);

  SendPort sendPort2 = await receivePort.first;

  List<int> image = await sendReceive(sendPort2, [listInt, width, height]);

  return image;
}

Future sendReceive(SendPort port, msg) {
  ReceivePort response = new ReceivePort();
  port.send([msg, response.sendPort]);
  return response.first;
}

void insideIsolate(SendPort sendPort) async {

  ReceivePort port = ReceivePort();
  sendPort.send(port.sendPort);

  await for (var msg in port) {
    SendPort replyTo = msg[1];

    List<int> listInt = msg[0][0];
    int width = msg[0][1];
    int height = msg[0][2];

    dartImage.Image image = dartImage.Image.fromBytes(width, height, listInt);
    List<int> converted = dartImage.encodeJpg(dartImage.gaussianBlur(image, 100));
    replyTo.send(converted);

  }
}


