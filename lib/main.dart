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

    BmpARGB32Header rgba32Header = BmpARGB32Header(temp.width, temp.height);
    Uint8List converted = rgba32Header.getHeadered(listInt);

    ui.decodeImageFromList(converted, (image){
      value = image;
    });
  }

}

class BmpARGB32Header{
  int width;
  int height;

  Uint8List _bmp;
  int baseHeaderSize = 122;

  set bitmap(Uint8List bmp) => _bmp = bmp;
  int get size => (width * height) * 4;
  int get fileLength => baseHeaderSize + size;

  BmpARGB32Header(this.width, this.height) :  assert(width & 3 == 0) {
    _bmp = new Uint8List(fileLength);
    ByteData bd = _bmp.buffer.asByteData();
    bd.setUint8(0x0, 0x42);
    bd.setUint8(0x1, 0x4d);
    bd.setInt32(0x2, fileLength, Endian.little);
    bd.setInt32(0xa, baseHeaderSize, Endian.little);
    // info header
    bd.setUint32(0xe, 108, Endian.little);
    bd.setUint32(0x12, width, Endian.little);
    bd.setUint32(0x16, height, Endian.little);
    bd.setUint16(0x1a, 1, Endian.little);
    bd.setUint32(0x1c, 32, Endian.little); // pixel size
    bd.setUint32(0x1e, 3, Endian.little); //BI_BITFIELDS
    bd.setUint32(0x22, size, Endian.little);
    bd.setUint32(0x36, 0x000000ff, Endian.little);
    bd.setUint32(0x3a, 0x0000ff00, Endian.little);
    bd.setUint32(0x3e, 0x00ff0000, Endian.little);
    bd.setUint32(0x42, 0xff000000, Endian.little);
  }

  Uint8List flipHorizontal(Uint8List bmp, int pixelLength){
    int lineLength = (width * pixelLength);
    int halfLine = lineLength ~/2;

    for( int line = 0; line < height; line++)  {
      int startOfLine = line * lineLength;
      for(int relativeColumnStart = 0; relativeColumnStart < halfLine; relativeColumnStart+=pixelLength){
        int pixelStart = startOfLine + relativeColumnStart;
        int pixelEnd = pixelStart + pixelLength;

        int relativeOppositePixelStart = lineLength - relativeColumnStart - pixelLength;
        int oppositePixelStart = startOfLine + relativeOppositePixelStart;
        int oppositePixelEnd = oppositePixelStart + pixelLength;

        Uint8List oppositePixel = bmp.sublist(oppositePixelStart, oppositePixelEnd);
        Uint8List targetPixel = bmp.sublist(pixelStart, pixelEnd);

        bmp.setRange(oppositePixelStart, oppositePixelEnd, targetPixel);
        bmp.setRange(pixelStart, pixelEnd, oppositePixel);
      }
    }

    return bmp;
  }

  Uint8List flipVertical(Uint8List bmp, int pixelLength){
    int lineLength = (width * pixelLength);
    int halfHeight = height ~/2;
    for(int line = 0; line < halfHeight; line++){
      int startOfLine = line * lineLength;
      int startOfOppositeLine = (height - 1 - line) * lineLength;
      for(int column = 0; column < width; column++){
        int pixelStart = startOfLine + column * 4;
        int pixelEnd = pixelStart + pixelLength;

        int oppositePixelStart = startOfOppositeLine + column * 4;
        int oppositePixelEnd = oppositePixelStart + pixelLength;

        Uint8List oppositePixel = bmp.sublist(oppositePixelStart, oppositePixelEnd);
        Uint8List targetPixel = bmp.sublist(pixelStart, pixelEnd);

        bmp.setRange(oppositePixelStart, oppositePixelEnd, targetPixel);
        bmp.setRange(pixelStart, pixelEnd, oppositePixel);
      }
    }

    return bmp;
  }



  Uint8List getHeadered(Uint8List bmp) {
    assert(bmp.length == size);

    Uint8List flipped = Uint8List.fromList(bmp);

    //flipHorizontal(flipped, 4);
    flipVertical(flipped, 4);

    return Uint8List.fromList(_bmp)..setRange(baseHeaderSize, fileLength, flipped);
  }

}