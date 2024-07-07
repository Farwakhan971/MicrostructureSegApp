import 'dart:async';
import 'package:flutter/material.dart';
import 'Login_screen.dart';
import 'tflite_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late TFLiteService tfliteService;

  @override
  void initState() {
    super.initState();
    tfliteService = TFLiteService();
    _loadModelAndNavigate();
  }

  Future<void> _loadModelAndNavigate() async {
    try {
      await tfliteService.loadModel();
      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen(tfliteService)),
        );
      });
    } catch (e) {
      // Handle model loading failure
      print("Error loading model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/kidney.jpeg',
        ),
      ),
    );
  }
}
