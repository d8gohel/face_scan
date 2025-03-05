import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  // final CameraDescription camera;
  final Function(XFile)
  onImageCaptured; // Callback function to return the XFile

  const CameraScreen({
    super.key,
    // required this.camera,
    required this.onImageCaptured, // Add the callback as a parameter
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // late CameraController _controller;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late String imagePath;
  bool isFrontCamera = true; // Keep track of camera direction

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Method to initialize the camera
  void _initializeCamera() {
    // Get the list of available cameras
    availableCameras().then((cameras) {
      final camera = cameras[isFrontCamera ? 1 : 0]; // Front or back camera
      _controller = CameraController(camera, ResolutionPreset.high);

      _initializeControllerFuture =
          _controller.initialize(); // Initialize the controller
      setState(() {}); // Trigger rebuild to reflect the initialized camera
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> _captureAndCropImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      imagePath = image.path;

      widget.onImageCaptured(image); // Pass the captured image back

      if (!mounted) return;
      Navigator.pop(context); // Optionally navigate or show a message
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing image: $e');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("capture"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isFrontCamera = !isFrontCamera; // Toggle the camera direction
              });
              _initializeCamera(); //
            },
            icon: Icon(Icons.flip_camera_android_sharp),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: [
                  Transform.flip(
                    flipX: isFrontCamera ? true : false,
                    child: RotatedBox(
                      quarterTurns:
                          isFrontCamera
                              ? 3
                              : 1, // Rotate the camera view 270 degrees
                      child: SizedBox(
                        width:
                            MediaQuery.sizeOf(
                              context,
                            ).height, // Set the width as the height of the device
                        child: CameraPreview(
                          _controller,
                          child: Stack(
                            children: [
                              // Add BackdropFilter for blur effect outside the circle
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 10.0,
                                    sigmaY: 10.0,
                                  ), // Adjust blur intensity
                                  child: Container(
                                    color: Colors.black.withOpacity(
                                      0,
                                    ), // Make sure the background is transparent
                                  ),
                                ),
                              ),
                              Center(
                                child: ClipOval(
                                  child: SizedBox(
                                    height:
                                        250, // Set the height to make it an oval
                                    width:
                                        300, // Set the width to make it an oval
                                    child: CameraPreview(_controller),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 5,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        width: MediaQuery.sizeOf(context).width,
                        child: TextButton(
                          onPressed: _captureAndCropImage,
                          child: Text(
                            "Capture Image",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
