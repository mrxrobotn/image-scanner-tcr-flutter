import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tesseract Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Tesseract Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _ocrText = '';
  String path = "";
  bool bload = false;

  Future<void> runFilePicker(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      _ocr(pickedFile.path);
    }
  }

  void _ocr(url) async {
    path = url;
    if (kIsWeb == false && (url.indexOf("http://") == 0 || url.indexOf("https://") == 0)) {
      Directory tempDir = await getTemporaryDirectory();
      HttpClient httpClient = HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      String dir = tempDir.path;
      print('$dir/test.jpg');
      File file = File('$dir/test.jpg');
      await file.writeAsBytes(bytes);
      url = file.path;
    }

    bload = true;
    setState(() {});

    _ocrText = await FlutterTesseractOcr.extractText(url, language: 'eng', args: {
      "preserve_interword_spaces": "1",
    });

    bload = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        runFilePicker(ImageSource.gallery);
                      },
                      child: Text("Pick from Gallery"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        runFilePicker(ImageSource.camera);
                      },
                      child: Text("Take a Photo"),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      path.isEmpty
                          ? Container()
                          : path.startsWith("http")
                          ? Image.network(path)
                          : Image.file(File(path)),
                      bload
                          ? Column(
                        children: [CircularProgressIndicator()],
                      )
                          : Text('$_ocrText'),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: kIsWeb
          ? Container()
          : FloatingActionButton(
        onPressed: () {
          runFilePicker(ImageSource.camera);
        },
        tooltip: 'OCR',
        child: Icon(Icons.add),
      ),
    );
  }
}
