import 'package:dartimage/isolate_manager.dart';

import 'dart:isolate';




imageIsolate(List initialMessage){
  print("gonna do");
  List<int> listInt = initialMessage[0];
  int width = initialMessage[1];
  int height = initialMessage[2];
  double contrast = initialMessage[3];

  /***/




  /***/
  print("did");
  return listInt;

}


Future<List<int>> doStuff(List<int> listInt, int width, int height, double contrast) async {
  List<int> image = imageIsolate([listInt, width, height, contrast]);
  return image;
}


