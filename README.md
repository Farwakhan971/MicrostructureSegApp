# Microvasculature Segmentation App

This Flutter application is designed to perform microvasculature segmentation on kidney histology images. It leverages a TensorFlow Lite model for image segmentation and integrates with Firebase for authentication and backend support. The application is particularly useful for medical professionals and researchers who need to analyze kidney tissue images for microvasculature patterns.

## Features

- **Image Segmentation**: The core feature of this application is its ability to segment microvasculature in kidney histology images using a TensorFlow Lite model with 67% accuracy.
- **Firebase Integration**: The app integrates with Firebase for authentication, ensuring secure access and user management.
- **Image Picker**: Users can select images from their gallery or capture new ones using the device's camera.
- **Segmentation Visualization**: After segmentation, the app displays the segmented images, allowing users to easily visualize the microvasculature patterns.

## Application Overview

### main.dart

This is the main entry point of the application. Key functionalities include:

- **Firebase Initialization**: The app initializes Firebase with the necessary configurations.
- **TensorFlow Lite Model Loading**: An instance of `TFLiteService` is created, and the TensorFlow Lite model is loaded.
- **User Authentication**: The app signs out any authenticated user at startup.
- **UI Setup**: The main widget, `MyApp`, sets up the application’s home screen, directing users to the `SplashScreen`.

### SegmentationScreen

The `SegmentationScreen` handles the core functionality of image selection and segmentation:

- **Image Selection**: Users can pick images from their gallery or capture new ones.
- **Segmentation Processing**: Once an image is selected, the app uses the TensorFlow Lite model to perform segmentation.
- **Image Display**: The original and segmented images are displayed to the user.

### tflite_service.dart

The `TFLiteService` class is responsible for:

- **Model Loading**: Loading the TensorFlow Lite model from the assets.
- **Running Predictions**: Processing the input image data and running the segmentation model to get the output.

## How It Works

1. **Model Integration**: The app uses a TensorFlow Lite model trained to segment microvasculature in kidney histology images with 67% accuracy.
2. **Image Selection**: Users can select or capture an image of kidney tissue.
3. **Segmentation**: The selected image is processed by the TensorFlow Lite model to identify and segment microvasculature.
4. **Visualization**: The app displays both the original and segmented images for easy comparison and analysis.

## Usefulness

This app is useful for:

- **Medical Research**: Assisting researchers in studying kidney microvasculature patterns, which can be crucial for understanding various kidney diseases.
- **Medical Professionals**: Helping doctors and pathologists in diagnosing conditions related to kidney microvasculature by providing a quick and automated segmentation tool.
- **Educational Purposes**: Serving as a learning tool for students and professionals in the medical field to understand the intricacies of kidney microvasculature.

By leveraging advanced machine learning models and providing an easy-to-use interface, this app facilitates detailed and accurate analysis of kidney histology images, making it a valuable tool in the medical domain.

<img src="https://github.com/user-attachments/assets/c55555ba-6666-4de1-9a1c-f3fd64c8a7b1" width="200" alt="Splash_screen">
<img src="https://github.com/user-attachments/assets/e5fee5d6-a086-48bf-a6f3-9660a76e6411" width="200" alt="Sign-Up-screen">
<img src="https://github.com/user-attachments/assets/74de88cf-16b6-4424-b6bc-ae24b4b74b75" width="200" alt="Login-screen">
<img src="https://github.com/user-attachments/assets/a81c512c-8039-48b3-a037-14ab1c4edad2" width="200" alt="Segmentation_Screen">
<img src="https://github.com/user-attachments/assets/db030f1c-a8ab-46f9-a534-4455344825de" width="200" alt="Image_Export">





