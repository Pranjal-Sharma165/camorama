import 'dart:html';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

void main() {
  // Create video and canvas globally
  final video = VideoElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..autoplay = true
    ..muted = true;

  final canvas = CanvasElement();

  // Start the camera
  window.navigator.mediaDevices?.getUserMedia({'video': true}).then((stream) {
    video.srcObject = stream;
  }).catchError((e) {
    print('Error accessing webcam: $e');
  });

  // Register the video element
  ui.platformViewRegistry.registerViewFactory('cameraPreview', (int viewId) => video);

  runApp(MyApp(video: video, canvas: canvas));
}

class MyApp extends StatefulWidget {
  final VideoElement video;
  final CanvasElement canvas;

  const MyApp({Key? key, required this.video, required this.canvas}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? capturedImageDataUrl;

  void capturePicture() {
    widget.canvas.width = widget.video.videoWidth;
    widget.canvas.height = widget.video.videoHeight;

    final ctx = widget.canvas.context2D;
    ctx.drawImage(widget.video, 0, 0);

    final dataUrl = widget.canvas.toDataUrl('image/png');

    setState(() {
      capturedImageDataUrl = dataUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Camorama'),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: HtmlElementView(viewType: 'cameraPreview'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ElevatedButton(
                onPressed: capturePicture,
                child: const Text('Capture Picture'),
              ),
            ),
            if (capturedImageDataUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Image.network(
                  capturedImageDataUrl!,
                  width: 200,
                  height: 300,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
