// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

void main() {
  ui.platformViewRegistry.registerViewFactory(
    'my-view-type',
    (int viewId) => DivElement()..text = 'Hello from HTML!',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: HtmlElementView(viewType: 'my-view-type'),
      ),
    );
  }
}
