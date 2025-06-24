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

  runApp(MyAppRoot(video: video, canvas: canvas));
}

class MyAppRoot extends StatelessWidget {
  final VideoElement video;
  final CanvasElement canvas;

  const MyAppRoot({Key? key, required this.video, required this.canvas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camorama',
      home: HomePage(video: video, canvas: canvas),
    );
  }
}

class HomePage extends StatefulWidget {
  final VideoElement video;
  final CanvasElement canvas;

  const HomePage({Key? key, required this.video, required this.canvas}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  List<String> capturedImages = [];
  List<String> selectedForCollage = [];
  int? countdown;
  bool showCollage = false;
  String? selectedImage;
  final FocusNode _focusNode = FocusNode();
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('How to Use'),
              content: const Text(
                '• Press Enter or tap "Capture Picture" to take a photo.\n'
                '• Click on images at the bottom to select up to 3.\n'
                '• Tap the "Click" button to view the collage.\n\n'
                'Tip: Click the same image again to unselect it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it!'),
                ),
              ],
            );
          },
        );
      });
    }
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
    final collageImages = selectedForCollage;
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
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
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
                  if (selectedForCollage.length == 3) {
                    setState(() {
                      showCollage = true;
                    });
                  } else {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Select exactly 3 images for the collage.')),
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
                              if (selectedForCollage.contains(img)) {
                                selectedForCollage.remove(img);
                              } else {
                                if (selectedForCollage.length < 3) {
                                  selectedForCollage.add(img);
                                } else {
                                  scaffoldMessengerKey.currentState?.showSnackBar(
                                    const SnackBar(content: Text('You can select up to 3 images for the collage.')),
                                  );
                                }
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedForCollage.contains(img)
                                    ? Colors.green
                                    : (selectedImage == img ? Colors.deepPurple : Colors.transparent),
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
    _focusNode.dispose();
    super.dispose();
  }
}
