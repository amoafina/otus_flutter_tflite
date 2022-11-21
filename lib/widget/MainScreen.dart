import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otus_tflite_test/helper/app_string.dart';
import 'package:otus_tflite_test/service/tensor_isolate.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => new _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  File _image;
  List _recognitions;
  String _model = AppString.ssd;
  double _imageHeight;
  double _imageWidth;

  SendPort _tensorIsolate;

  @override
  void initState() {
    super.initState();
    initIsolate().then((SendPort value) {
      _tensorIsolate = value;
    });
  }

  Future<SendPort> initIsolate() async {
    Completer completer = new Completer<SendPort>();
    ReceivePort recievePort = ReceivePort();

    recievePort.listen((data) {
      if (data is SendPort) {
        SendPort mainToIsolateStream = data;
        completer.complete(mainToIsolateStream);
      } else {        
        setState(() {
          _recognitions = jsonDecode(data);
        });
      }
    });

    await FlutterIsolate.spawn(ITensor.init, recievePort.sendPort);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null ? Text('No image selected.') : Image.file(_image),
    ));

    stackChildren.addAll(_renderBoxes(size));

    return Scaffold(
      appBar: AppBar(
        title: Text(_model),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _onSelect,
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> menuEntries = [
                const PopupMenuItem<String>(
                  child: Text(AppString.ssd),
                  value: AppString.ssd,
                ),
                const PopupMenuItem<String>(
                  child: Text(AppString.yolo),
                  value: AppString.yolo,
                ),
              ];
              return menuEntries;
            },
          )
        ],
      ),
      body: Stack(
        children: stackChildren,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _predictImagePicker,
        tooltip: 'Pick Image',
        child: Icon(Icons.camera),
      ),
    );
  }

  void _onSelect(model) async {
    setState(() {
      _model = model;
      _recognitions = null;
    });

    if (_image != null) {
      _predictImage(_image);
    }
  }

  List<Widget> _renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageWidth * screen.width;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return _recognitions.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: blue,
              width: 2,
            ),
          ),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  Future _predictImagePicker() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    _predictImage(image);
  }

  Future _predictImage(File image) async {
    if (image == null) return;

    _tensorIsolate.send([_model, image.readAsBytesSync()]);

    new FileImage(image)
        .resolve(new ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageHeight = info.image.height.toDouble();
        _imageWidth = info.image.width.toDouble();
      });
    }));

    setState(() {
      _image = image;
    });
  }
}
