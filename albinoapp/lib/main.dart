import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'flutter_document_picker.dart' show File;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          _buildGridItem(context, 'Kamera', Colors.red, CameraScreen()),
          _buildGridItem(context, 'Belgeler', Colors.blue, DocumentsScreen()),
          _buildGridItem(context, 'Galeri', Colors.green, GalleryScreen()),
          _buildGridItem(context, 'Ayarlar', Colors.yellow, SettingsScreen()),
        ],
      ),
    );
  }

  Widget _buildGridItem(
      BuildContext context, String title, Color color, Widget screen) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
      child: Card(
        color: color,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  List<CameraDescription> cameras = [];

  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    availableCameras().then((value) {
      setState(() {
        cameras = value;
        _controller = CameraController(cameras[0], ResolutionPreset.medium);
        _controller.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        });
      });
    });
    _initializeCamera();
  }

  void _initializeCamera() async {
    // Kamera listesini al
    List<CameraDescription> cameras = await availableCameras();

    // İlk kamerayı seç
    CameraDescription camera = cameras.first;

    // Kamera kontrolörünü oluştur ve başlat
    _controller = CameraController(camera, ResolutionPreset.high);

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Kamera hazır ise önizlemeyi göster
            return CameraPreview(_controller);
          } else {
            // Kamera hazır olana kadar yükleniyor göster
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            // Fotoğraf çek ve sonucu al
            final XFile photo = await _controller.takePicture();

            // Çekilen fotoğrafı başka bir sayfada göstermek için yeni sayfaya geçiş yap
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoPreviewScreen(imagePath: photo.path),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;

  const PhotoPreviewScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Preview'),
      ),
      body: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      ),
    );
  }
}
class FlutterDocumentPickerParams {
  final List<String> allowedFileExtensions;
  final List<String> allowedUtiTypes;
  final List<String> allowedMimeTypes;
  final List<String> invalidFileNameSymbols;

  FlutterDocumentPickerParams({required this.allowedFileExtensions, required this.allowedUtiTypes, required this.allowedMimeTypes, required this.invalidFileNameSymbols});
}
class FlutterDocumentPicker extends StatelessWidget {
  final FlutterDocumentPicker params;

  const FlutterDocumentPicker({Key? key, required this.params, required List<String> allowedUtiTypes, required List<String> allowedFileExtensions, required List<String> allowedMimeTypes, required List<String> invalidFileNameSymbols}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final path = await FlutterDocumentPicker.openDocument(params: params);
        print('Document path: $path');
      },
      child: Text('Pick a document'),
    );
  }

  static openDocument({required FlutterDocumentPicker params}) {}
}


class DocumentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Pick a document'),
          onPressed: () async {
            var params = FlutterDocumentPickerParams(
              allowedFileExtensions: ['pdf', 'doc', 'docx'],
              allowedUtiTypes: ['com.adobe.pdf', 'org.openxmlformats.wordprocessingml.document', 'com.microsoft.word.doc'],
              allowedMimeTypes: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
              invalidFileNameSymbols: ['/'],
            );

            final path = await FlutterDocumentPicker.openDocument(params: params);

            print('Document path: $path');
          },
        ),
      ),
    );
  }

  FlutterDocumentPickerParams({required List<String> allowedFileExtensions, required List<String> allowedUtiTypes, required List<String> allowedMimeTypes, required List<String> invalidFileNameSymbols}) {}
}

class GalleryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
      ),
      body: Center(
        child: Text('Gallery Screen'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}
