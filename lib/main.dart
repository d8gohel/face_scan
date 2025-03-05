// import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:face_camera/camerascreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Selfie App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SelfiePage(camera: camera),
    );
  }
}

class SelfiePage extends StatefulWidget {
  final CameraDescription camera;

  const SelfiePage({super.key, required this.camera});

  @override
  // ignore: library_private_types_in_public_api
  _SelfiePageState createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> {
  CameraController? _controller;
  XFile? _image1;
  XFile? _image2;
  bool loader = false;
  Dio dio = Dio();
  Map data = {};
  // final TextEditingController urlcontroller = TextEditingController();
  // final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Method to pick an image from the camera
  Future<void> _pickImage(int imageNumber) async {
    // final picker = ImagePicker();
    var pickedFile;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CameraScreen(
              onImageCaptured: (XFile image) {
                pickedFile = image;
              },
            ),
      ),
    );
    // log(pickedFile.);

    if (pickedFile != null) {
      setState(() {
        if (imageNumber == 1) {
          _image1 = XFile(pickedFile.path);
        } else if (imageNumber == 2) {
          _image2 = XFile(pickedFile.path);
        }
      });
    }
  }

  // Method to handle the image matching request
  Future<void> _matchImages() async {
    try {
      setState(() {
        loader = true;
      });

      FormData f = FormData.fromMap({
        "ref_image": await MultipartFile.fromFile(_image1!.path),
        "image": await MultipartFile.fromFile(_image2!.path),
      });

      Response response = await dio
          .post("http://43.204.175.127:50056/match_face_test", data: f)
          .timeout(Duration(seconds: 60));
      setState(() {
        loader = false;
        data = response.data ?? data;
      });
      log(data.toString());
    } catch (e) {
      if (e is DioException) {}
      setState(() {
        loader = false;
        data = {"status": "not reached"};
      });
    }
    // log();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face recognition'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _image1 != null
                                ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    // height: 500,
                                    child: Column(
                                      children: [
                                        Text('first image'),
                                        Transform.flip(
                                          flipX: true,
                                          child: Image.file(
                                            File(_image1!.path),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : Center(child: Text('No first image ')),
                            TextButton(
                              onPressed: () => _pickImage(1),
                              child: Center(child: Text('Pick First Image ')),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _image2 != null
                                ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    // height: 500,
                                    child: Column(
                                      children: [
                                        Text('second image'),
                                        Transform.flip(
                                          flipX: true,
                                          child: Image.file(
                                            File(_image2!.path),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : Text('No second image '),
                            TextButton(
                              onPressed: () => _pickImage(2),
                              child: Text('Pick Second Image'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              loader == true
                  ? CircularProgressIndicator()
                  : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.all(width: 1),
                      children: [
                        TableRow(
                          children: [
                            Center(child: Text("Status")),
                            Center(
                              child: Text(data["status"]?.toString() ?? "N/A"),
                            ), // Centered text
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(child: Text("Status code")),
                            Center(
                              child: Text(
                                data["statusCode"]?.toString() ?? "N/A",
                              ),
                            ), // Centered text
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(child: Text("Message")),
                            Center(
                              child: Text(
                                data["message"] ?? "No message available",
                              ),
                            ), // Centered text
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(child: Text("user_id")),
                            Center(
                              child: Text(
                                data["user_id"] ?? "No message available",
                              ),
                            ), // Centered text
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(child: Text("user")),
                            Center(
                              child: Text(
                                data["user"] ?? "No message available",
                              ),
                            ), // Centered text
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(child: Text("request_id")),
                            Center(
                              child: Text(data["requestId"].toString()),
                            ), // Centered text
                          ],
                        ),
                      ],
                    ),
                  ),
              SizedBox(height: 20),
              TextButton(
                onPressed:
                    _image1 != null && _image2 != null
                        ? () {
                          // if (_formKey.currentState?.validate() ?? false) {
                          _matchImages();
                          // }
                        }
                        : null,
                child: Text('Match Faces'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
