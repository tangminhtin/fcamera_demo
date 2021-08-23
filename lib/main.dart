import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  List<CameraDescription> cameras = [];

  void logError(String code, String? message) {
    if (message != null) {
      print('Error: $code\nError Message: $message');
    } else {
      print('Error: $code');
    }
  }

  // Ensure plugin is initialized
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras(); // get list of cameras
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }

  runApp(MyApp(firstCamera: cameras.first));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final firstCamera;

  MyApp({this.firstCamera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color.fromRGBO(70, 224, 164, 1),
      ),
      home: TakePictureScreen(camera: firstCamera),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  CameraDescription camera;

  TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  double _currentZoomValue = 0;
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Display the current output from the Camera
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final PreferredSizeWidget appBar = AppBar(
      title: Text('Camera Demo'),
    );

    XFile? _imageFile;
    void _onPickImagePressed(BuildContext context) async {
      final ImagePicker _picker = ImagePicker();
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _imageFile = pickedFile;
      });

      if (_imageFile == null) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePath: _imageFile!.path,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          Center(
            child: Container(
              width: mediaQuery.size.width,
              height: (mediaQuery.size.height -
                      appBar.preferredSize.height -
                      mediaQuery.padding.top) *
                  0.8,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      child: FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return CameraPreview(_controller!);
                            // return Container(color: Colors.pink);
                          } else {
                            return Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                    Positioned(
                      top: 110,
                      left: 20,
                      child: IconButton(
                        iconSize: 300,
                        onPressed: () {},
                        icon: Icon(
                          Icons.crop_free_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _controller!.setFlashMode(FlashMode.auto);
                                  },
                                  icon: Icon(
                                    Icons.flash_on,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      // print(widget.camera.lensDirection);
                                      // _controller!.description.lensDirection == CameraLensDirection.back
                                    });
                                  },
                                  icon: Icon(
                                    Icons.flip_camera_ios,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 50,
                      child: Column(
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Container(
                              child: Slider(
                                value: _currentZoomValue,
                                min: 0,
                                max: 4,
                                onChanged: (double value) {
                                  setState(() {
                                    _currentZoomValue = value;
                                    _controller!
                                        .setZoomLevel(_currentZoomValue);
                                  });
                                },
                              ),
                            ),
                          ),
                          Icon(
                            Icons.remove,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: (mediaQuery.size.height -
                    appBar.preferredSize.height -
                    mediaQuery.padding.top) *
                0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              // color: Colors.black12,
              // backgroundBlendMode: BlendMode.overlay,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => _onPickImagePressed(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(30),
                      ),
                    ),
                    primary: Theme.of(context).primaryColor,
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Photos'),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(100),
                    ),
                    // color: Colors.red,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 4,
                    ),
                  ),
                  padding: EdgeInsets.all(3),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _controller!.takePicture().then((value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DisplayPictureScreen(imagePath: value.path),
                            ),
                          );
                        });
                      } catch (e) {
                        print(e);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(100),
                        ),
                      ),
                      primary: Theme.of(context).primaryColor,
                      minimumSize: Size(70, 70),
                    ),
                    child: null,
                  ),
                ),
                FittedBox(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      primary: Theme.of(context).primaryColor,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.help_outline_rounded),
                        Text('Instructions'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  _upLoadImage(File image) async {
    String path = image.path;
    var name = path.substring(path.lastIndexOf("/") + 1, path.length);
    var suffix = name.substring(name.lastIndexOf(".") + 1, name.length);
    FormData formData = FormData.fromMap(
        {"image_file": await MultipartFile.fromFile(path, filename: name)});

    Dio dio = new Dio();
    var respone = await dio.post<String>(
        "http://6d9b-2402-800-6344-a20b-f03a-6de4-b8c-9e4.ngrok.io/",
        data: formData);
    if (respone.statusCode == 200) {
      Fluttertoast.showToast(
          msg: 'Success!',
          gravity: ToastGravity.BOTTOM,
          textColor: Colors.grey);
      // setState(() {
      //   _label = jsonDecode(respone.data.toString())['label'];
      //   _score = jsonDecode(respone.data.toString())['score'];
      //   loadingdone = true;
      // });
    } else {
      Fluttertoast.showToast(
          msg: 'Error!', gravity: ToastGravity.BOTTOM, textColor: Colors.grey);
    }
  }

  Future getImage(File image) async {
    // var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    _upLoadImage(image);
    // setState(() {
    //   _image = image;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Display the picture'),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              height: mediaQuery.size.height * 0.8,
              child: Center(
                child: Image.file(
                  File(widget.imagePath),
                ),
              ),
            ),
            Container(
              child: FittedBox(
                child: ElevatedButton(
                  onPressed: () async {
                    getImage(File(widget.imagePath));
                  },
                  child: Text('Click me'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
