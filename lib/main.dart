import 'package:flutter/material.dart';
import 'package:otus_tflite_test/widget/MainScreen.dart';

void main() {
  runApp(new App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen()
    );
  }
}