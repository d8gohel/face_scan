import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  final Function(XFile)
  onImageCaptured; // Callback function to return the captured image

  const CameraScreen({super.key, required this.onImageCaptured});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool isFrontCamera = true; // Keep track of camera direction

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Method to initialize the camera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras found");
      }

      final camera =
          (cameras.length > 1 && isFrontCamera) ? cameras[1] : cameras[0];

      _controller = CameraController(camera, ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize();

      setState(() {}); // Rebuild UI once camera is initialized
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing camera: $e");
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndCropImage() async {
    try {
      await _initializeControllerFuture;
      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception("Camera is not ready.");
      }

      final image = await _controller!.takePicture();

      widget.onImageCaptured(image); // Pass captured image back

      if (!mounted) return;
      Navigator.pop(context); // Optionally navigate back
    } catch (e) {
      if (kDebugMode) {
        print("Error capturing image: $e");
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error capturing image: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Capture")),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _controller != null) {
              return Stack(
                children: [
                  Transform.flip(
                    flipX: isFrontCamera,
                    child: RotatedBox(
                      quarterTurns: isFrontCamera ? 3 : 1,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).height,
                        child: CameraPreview(
                          _controller!,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 10.0,
                                    sigmaY: 10.0,
                                  ),
                                  child: Container(
                                    color: Colors.black.withOpacity(0),
                                  ),
                                ),
                              ),
                              Center(
                                child: ClipOval(
                                  child: SizedBox(
                                    height: 250,
                                    width: 300,
                                    child: CameraPreview(_controller!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Capture Button
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
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        width: MediaQuery.sizeOf(context).width,
                        child: TextButton(
                          onPressed: _captureAndCropImage,
                          child: const Text(
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
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
