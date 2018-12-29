import 'dart:async';

import 'dart:typed_data';

import 'package:dartimage/dartimage_manipulation.dart';
import 'package:flutter/material.dart';

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
    List<int> converted = await doStuff(listInt, temp.width, temp.height);
    ui.decodeImageFromList(converted, (image){
      value = image;
    });
  }

}

