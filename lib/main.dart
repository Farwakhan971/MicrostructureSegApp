import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:microstructure/splash_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:another_flushbar/flushbar.dart';
import 'tflite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TFLiteService tfliteService = TFLiteService();
  await tfliteService.loadModel();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "",
      appId: "",
      messagingSenderId: "",
      projectId: "",
    ),
  );
  FirebaseAuth.instance.signOut();
  runApp(MyApp(tfliteService));
}

class MyApp extends StatelessWidget {
  final TFLiteService tfliteService;

  MyApp(this.tfliteService);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SegmentationScreen extends StatefulWidget {
  final TFLiteService tfliteService;

  SegmentationScreen(this.tfliteService);

  @override
  _SegmentationScreenState createState() => _SegmentationScreenState();
}

class _SegmentationScreenState extends State<SegmentationScreen> with SingleTickerProviderStateMixin {
  File? _image;
  File? _segmentedImage;
  final picker = ImagePicker();
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!is2DPASStainedKidneyImage(pickedFile.path)) {
        showFlushbar("Invalid image", "Please select a 2D-PAS stained kidney image.", Colors.red, Icons.error);
        return;
      }

      setState(() {
        _image = File(pickedFile.path);
        _segmentedImage = null;
      });
    } else {
      showFlushbar("No image selected", "Please select an image to proceed.", Colors.red, Icons.error);
    }
  }

  Future segmentImage() async {
    if (_image == null) {
      showFlushbar("No image selected", "Please select an image first.", Colors.red, Icons.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List inputBytes = await _image!.readAsBytes();
      img.Image originalImage = img.decodeImage(inputBytes)!;

      img.Image resizedImage = img.copyResize(originalImage, width: 512);

      List<List<List<List<double>>>> input = imageToInput(resizedImage);
      List<List<List<List<double>>>> output = await widget.tfliteService.predict(input);

      img.Image maskImage = createMaskImage(output);
      img.Image resultImage = overlayImages(originalImage, maskImage);

      final directory = await getApplicationDocumentsDirectory();
      String outputPath = '${directory.path}/segmented_image.png';
      File(outputPath).writeAsBytesSync(img.encodePng(resultImage));

      setState(() {
        _segmentedImage = File(outputPath);
        _isLoading = false;
      });

      _controller.forward();
    } catch (e) {
      print("Error predicting: $e");
      showFlushbar("Error predicting", "An error occurred during segmentation. Please try again.", Colors.red, Icons.error);
    }
  }

  void showFlushbar(String title, String message, Color color, IconData icon) {
    Flushbar(
      title: title,
      message: message,
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: color,
      icon: Icon(
        icon,
        color: Colors.white,
      ),
    ).show(context);
  }

  bool is2DPASStainedKidneyImage(String imagePath) {
    return true;
  }

  List<List<List<List<double>>>> imageToInput(img.Image image) {
    var input = List.generate(1, (_) => List.generate(512, (_) => List.generate(512, (_) => List.generate(3, (_) => 0.0))));

    for (int y = 0; y < 512; y++) {
      for (int x = 0; x < 512; x++) {
        var pixel = image.getPixel(x, y);
        input[0][y][x][0] = img.getRed(pixel) / 255.0;
        input[0][y][x][1] = img.getGreen(pixel) / 255.0;
        input[0][y][x][2] = img.getBlue(pixel) / 255.0;
      }
    }
    return input;
  }

  img.Image createMaskImage(List<List<List<List<double>>>> output) {
    int height = output[0].length;
    int width = output[0][0].length;
    img.Image maskImage = img.Image(width, height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int value = (output[0][y][x][0] * 255).toInt();
        maskImage.setPixel(x, y, img.getColor(255, 0, 0, value));
      }
    }

    return maskImage;
  }

  img.Image overlayImages(img.Image original, img.Image mask) {
    img.Image blended = img.copyResize(original, width: mask.width, height: mask.height);

    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        int maskPixel = mask.getPixel(x, y);
        int originalPixel = blended.getPixel(x, y);

        int blendedPixel = alphaBlend(originalPixel, maskPixel);
        blended.setPixel(x, y, blendedPixel);
      }
    }

    return blended;
  }

  int alphaBlend(int dstColor, int srcColor) {
    int dstA = img.getAlpha(dstColor);
    int dstR = img.getRed(dstColor);
    int dstG = img.getGreen(dstColor);
    int dstB = img.getBlue(dstColor);

    int srcA = img.getAlpha(srcColor);
    int srcR = img.getRed(srcColor);
    int srcG = img.getGreen(srcColor);
    int srcB = img.getBlue(srcColor);

    double srcAlpha = srcA / 255.0;
    double outAlpha = srcAlpha + dstA * (1 - srcAlpha) / 255.0;
    int outR = ((srcR * srcAlpha + dstR * (1 - srcAlpha)).clamp(0, 255)).toInt();
    int outG = ((srcG * srcAlpha + dstG * (1 - srcAlpha)).clamp(0, 255)).toInt();
    int outB = ((srcB * srcAlpha + dstB * (1 - srcAlpha)).clamp(0, 255)).toInt();
    int outA = (outAlpha * 255).toInt();

    return img.getColor(outR, outG, outB, outA);
  }

  Future exportSegmentedImage() async {
    if (_segmentedImage != null) {
      try {
        final directory = await getExternalStorageDirectory();
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String outputPath = '${directory!.path}/segmented_image_$timestamp.png';
        await _segmentedImage!.copy(outputPath);
        showFlushbar("Export successful", "The segmented image has been exported to $outputPath", Colors.green, Icons.check);
      } catch (e) {
        print("Failed to export the image: $e");
        showFlushbar("Export failed", "Failed to export the image. Please try again.", Colors.red, Icons.error);
      }
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Image Segmentation', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: _segmentedImage == null
            ? []
            : [
          IconButton(
            icon: Icon(Icons.save_alt, color: Colors.white),
            onPressed: exportSegmentedImage,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null
                  ? Text('No image selected.')
                  : Container(
                margin: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Image.file(
                  _image!,
                  width: 300,
                  height: 300,
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _segmentedImage == null
                    ? Container()
                    : ScaleTransition(
                  scale: _animation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      _segmentedImage!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),


              SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickImage,
                child: Text('Pick Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : segmentImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: _isLoading ? 0.0 : 1.0,
                      child: Text('Perform Segmentation'),
                    ),
                    if (_isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}

