
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:otus_tflite_test/helper/app_string.dart';
import 'package:tflite/tflite.dart';

class Tensor {
  Future loadModel(String model) async {
    Tflite.close();
    try {
      switch (model) {
        case AppString.yolo:
          await Tflite.loadModel(
            model: "assets/yolov2_tiny.tflite",
            labels: "assets/yolov2_tiny.txt",
          );
          break;
        case AppString.ssd:
          await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt",
          );
          break;
      }
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  Future yolov2Tiny(File image) async {
    return await Tflite.detectObjectOnImage(
      path: image.path,
      model: "YOLO",
      threshold: 0.3,
      imageMean: 0.0,
      imageStd: 255.0,
      numResultsPerClass: 1,
    );
  }

  Future ssdMobileNet(File image) async {
    return await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );
  }
}