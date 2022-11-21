import 'dart:convert';
import 'dart:isolate';
import 'dart:io';

import 'package:otus_tflite_test/helper/app_string.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';

class ITensor {
  static init(SendPort isolateToMainStream) {
    ReceivePort mainToIsolateStream = ReceivePort();
    isolateToMainStream.send(mainToIsolateStream.sendPort);

    mainToIsolateStream.listen((data) async {
      String _model = data[0];
      File _file = await File('${(await getTemporaryDirectory()).path}/image.png').create();
      _file.writeAsBytesSync(data[1]);

      List<dynamic> _result;

      switch (_model) {
        case AppString.yolo:
          await Tflite.loadModel(
            model: "assets/yolov2_tiny.tflite",
            labels: "assets/yolov2_tiny.txt",
          );
          _result = await Tflite.detectObjectOnImage(
            path: _file.path,
            model: "YOLO",
            threshold: 0.3,
            imageMean: 0.0,
            imageStd: 255.0,
            numResultsPerClass: 1,
          );
          break;
        case AppString.ssd:
          await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt",
          );
          _result = await Tflite.detectObjectOnImage(
            path: _file.path,
            numResultsPerClass: 1,
          );
          break;
      }
      isolateToMainStream.send(jsonEncode(_result));
    });
  }
}
