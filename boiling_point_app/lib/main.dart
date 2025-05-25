import 'package:flutter/material.dart';
import 'screens/input_screen.dart';

void main() {
  runApp(BoilingPointApp());
}

class BoilingPointApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boiling Point',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: InputScreen(),
    );
  }
}
