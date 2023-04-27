import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:image/image.dart'
    as img; // 'image' paketini içe aktarma ifadesini ekledik
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart' as img;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
        elevation: 8,
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
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Kamera listesini al
    cameras = await availableCameras();

    // İlk kamerayı seç
    CameraDescription camera = cameras.first;

    // Kamera kontrolörünü oluştur ve başlat
    _controller = CameraController(camera, ResolutionPreset.high);

    await _controller.initialize();
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
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoPreviewScreen(imagePath: photo.path),
              ),
            );

            if (result != null && !result) {
              await File(photo.path).delete();
            }
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () async {
          await _saveImageToGallery(imagePath);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fotoğraf galeriye kaydedildi.'),
            ),
          );
          Navigator.pop(context, true);
        },
      ),
    );
  }

  Future<void> _saveImageToGallery(String imagePath) async {
    final PermissionStatus permissionStatus = await Permission.photos.request();

    if (permissionStatus.isGranted) {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      final savedPath =
          await img.ImageGallerySaver.saveImage(img.encodeJpg(image!));

      print('Fotoğraf kaydedildi: $savedPath');
    } else {
      throw Exception('Fotoğraf izni verilmedi.');
    }
  }
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
              allowedUtiTypes: [
                'com.adobe.pdf',
                'org.openxmlformats.wordprocessingml.document',
                'com.microsoft.word.doc'
              ],
              allowedMimeTypes: [
                'application/pdf',
                'application/msword',
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
              ],
              invalidFileNameSymbols: ['/'],
            );
            final path =
                await FlutterDocumentPicker.openDocument(params: params);

            print('Document path: $path');
          },
        ),
      ),
    );
  }
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

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _fontSize = 16;
  Color _textColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(
              'Yazı boyutu: $_fontSize',
              style: TextStyle(fontSize: _fontSize, color: _textColor),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Yazı Boyutu'),
                    content: Slider(
                      value: _fontSize,
                      min: 8,
                      max: 32,
                      onChanged: (value) {
                        setState(() {
                          _fontSize = value;
                        });
                      },
                    ),
                    actions: [
                      TextButton(
                        child: Text('Tamam'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            title: Text(
              'Yazı rengi',
              style: TextStyle(fontSize: _fontSize, color: _textColor),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Yazı Rengi Seçin'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _textColor,
                        onColorChanged: (color) {
                          setState(() {
                            _textColor = color;
                          });
                        },
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Tamam'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
