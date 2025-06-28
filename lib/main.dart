import 'dart:html';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
    window.alert('Failed to access webcam. Please check permissions and reload the page.');
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
  bool collageCreated = false;
  String? selectedImage;

  final FocusNode _focusNode = FocusNode();
  bool _dialogShown = false;

  Color selectedBorderColor = Colors.black;
  double borderThickness = 8.0;

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
                '• Tap "Click" to preview the collage.\n'
                '• Then tap "Create Collage" to finalize the collage.\n'
                '• Change border colors using the buttons.\n\n'
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

  Widget framedImage(String img) {
    BoxDecoration decoration = BoxDecoration(
      border: Border.all(color: selectedBorderColor, width: borderThickness),
    );

    return Container(
      decoration: decoration,
      margin: const EdgeInsets.all(8),
      child: Image.network(
        img,
        width: 200,
        height: 260,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget collageWidget() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: selectedForCollage.map((img) {
            return framedImage(img);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (collageCreated) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: collageWidget(),
        ),
      );
    }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (selectedForCollage.length == 3) {
                        setState(() {
                          showCollage = true;
                        });
                      } else {
                        scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Select exactly 3 images for the collage.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Click'),
                  ),
                  const SizedBox(width: 10),
                  if (showCollage)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        const Text(
                          'Border Thickness',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          min: 2.0,
                          max: 20.0,
                          divisions: 9,
                          label: '${borderThickness.toInt()} px',
                          value: borderThickness,
                          onChanged: (value) {
                            setState(() {
                              borderThickness = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Border color selection
              if (showCollage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedBorderColor = Colors.black;
                          });
                        },
                        child: const Text('Black'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedBorderColor = Colors.white;
                          });
                        },
                        child: const Text('White'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Color tempColor = selectedBorderColor;
                          Color? pickedColor = await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Select Border Color'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: tempColor,
                                    onColorChanged: (color) {
                                      tempColor = color;
                                    },
                                    showLabel: true,
                                    pickerAreaHeightPercent: 0.8,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(tempColor),
                                    child: const Text('Select'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (pickedColor != null) {
                            setState(() {
                              selectedBorderColor = pickedColor;
                            });
                          }
                        },
                        child: const Text('Custom'),
                      ),
                    ],
                  ),
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
              if (!showCollage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: ElevatedButton(
                    onPressed: capturePicture,
                    child: const Text('Capture Picture'),
                  ),
                ),
              if (capturedImages.isNotEmpty && !showCollage)
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
                                    const SnackBar(
                                      content: Text(
                                        'You can select up to 3 images for the collage.',
                                      ),
                                    ),
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
                                    : (selectedImage == img
                                        ? Colors.deepPurple
                                        : Colors.transparent),
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
    final stream = widget.video.srcObject;
    if (stream != null) {
      stream.getTracks().forEach((track) => track.stop());
    }
    super.dispose();
  }
}
