import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Problem solver",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<StatefulWidget> {
  XFile? _image;
  String _responseBody = "";
  bool _isSending = false;
  String customPrompt = "";
  TextEditingController _controller = TextEditingController();
  _openCamera() {
    if (_image == null) {
      _getImageFromCamera();
    }
  }

  Future<void> _getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      ImageCropper cropper = ImageCropper();
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );
      setState(() {
        _image = croppedImage != null ? XFile(croppedImage.path) : null;
      });
    }
  }

  Future<void> sendImage(XFile? imagefile) async {
    if (imagefile == null) return;
    setState(() {
      _isSending = true;
    });
    String base64Image = base64Encode(File(imagefile.path).readAsBytesSync());
    String apiKey = "AIzaSyCBN1MiWZOfzMttkXbNLSOAtffRS9LdCzc";
    String requestBody = json.encode({
      "contents": [
        {
          "parts": [
            {
              "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
            },
            {
              "text": customPrompt == ""
                  ? "solve given maths function and provide step by step answer with explaination of each step"
                  : customPrompt
            },
            {"text": "input: "},
            {"text": "output: "}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 32,
        "topP": 1,
        "maxOutputTokens": 4096,
        "stopSequences": []
      },
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
    });
    http.Response response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro-vision-latest:generateContent?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: requestBody);
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonBody = json.decode(response.body);
      setState(() {
        _responseBody =
            jsonBody["candidates"][0]["content"]["parts"][0]["text"];
        _isSending = false;
      });
    } else {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Problem_solver"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _image == null
                    ? const Text("no image is selected!")
                    : Image.file(File(_image!.path)),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _controller,
                  onChanged: (value) => customPrompt = value,
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _responseBody,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
          ),
          if (_isSending)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _image == null ? _openCamera() : sendImage(_image);
        },
        tooltip: _image == null ? "Pick image" : 'send image',
        child: Icon(_image == null ? Icons.camera_alt : Icons.send),
      ),
    );
  }
}
