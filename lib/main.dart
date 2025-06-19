import 'dart:html';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  final video = VideoElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..autoplay = true
    ..muted = true;

  final canvas = CanvasElement();

  window.navigator.mediaDevices?.getUserMedia({'video': true}).then((stream) {
    video.srcObject = stream;
  }).catchError((e) {
    print('Error accessing webcam: $e');
  });

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
  List<String> capturedImages = [];
  int? countdown;
  bool showCollage = false;
  String? selectedImage;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  Future<void> capturePicture() async {
    for (int i = 3; i > 0; i--) {
      setState(() => countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() => countdown = null);

    widget.canvas.width = widget.video.videoWidth;
    widget.canvas.height = widget.video.videoHeight;

    final ctx = widget.canvas.context2D;
    ctx.drawImage(widget.video, 0, 0);

    final dataUrl = widget.canvas.toDataUrl('image/png');

    setState(() {
      capturedImages.add(dataUrl);
      selectedImage = dataUrl;
    });
  }

  Widget collageWidget() {
    final collageImages = capturedImages.take(3).toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: collageImages
            .map((img) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.network(
                    img,
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ))
            .toList(),
      ),
    );
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
        body: RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (RawKeyEvent event) {
            if (event.runtimeType == RawKeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              capturePicture();
            }
          },
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'If you are done with your images, click here:',
                style: TextStyle(fontSize: 16),
              ),
              ElevatedButton(
                onPressed: () {
                  if (capturedImages.length >= 3) {
                    setState(() {
                      showCollage = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Capture at least 3 images for a collage.')),
                    );
                  }
                },
                child: const Text('Click'),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      showCollage
                          ? collageWidget()
                          : HtmlElementView(viewType: 'cameraPreview'),
                      if (countdown != null)
                        Center(
                          child: Text(
                            '$countdown',
                            style: const TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: ElevatedButton(
                  onPressed: capturePicture,
                  child: const Text('Capture Picture'),
                ),
              ),
              if (capturedImages.isNotEmpty)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: GridView.builder(
                      itemCount: capturedImages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 4 / 3,
                      ),
                      itemBuilder: (context, index) {
                        final img = capturedImages[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImage = img;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedImage == img ? Colors.deepPurple : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Image.network(
                              img,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
