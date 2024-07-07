import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    try {
      final modelFile = await loadModelFile('assets/Segmentation_Model_MobileNetV2.tflite');
      _interpreter = await Interpreter.fromBuffer(modelFile);
      print("Model loaded successfully");
    } catch (e) {
      print("Failed to load model: $e");
      throw Exception("Failed to load model: $e");
    }
  }

  Future<Uint8List> loadModelFile(String filePath) async {
    final byteData = await rootBundle.load(filePath);
    return byteData.buffer.asUint8List();
  }

  Future<List<List<List<List<double>>>>> predict(List<List<List<List<double>>>> input) async {
    if (_interpreter == null) {
      throw Exception("Interpreter has not been initialized.");
    }

    var inputTensor = _interpreter.getInputTensor(0);
    var outputTensor = _interpreter.getOutputTensor(0);

    print("Input Tensor Shape: ${inputTensor.shape}");
    print("Output Tensor Shape: ${outputTensor.shape}");

    var output = List.generate(outputTensor.shape[0],
            (_) => List.generate(outputTensor.shape[1],
                (_) => List.generate(outputTensor.shape[2],
                    (_) => List.generate(outputTensor.shape[3], (_) => 0.0))));

    _interpreter.run(input, output);
    return output;
  }
}
