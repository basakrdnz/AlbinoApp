// Dart ile çalışan async programları desteklemek için gerekli
import 'dart:async';
// Dosya I/O işlemlerini gerçekleştirmek için gerekli
import 'dart:io';
// Byte veri türünü kullanmak için gerekli
import 'dart:typed_data';
// Flutter ile ilgili temel widget ve material tasarımı için gerekli
import 'package:flutter/material.dart';
// Kamera özelliklerini kullanmak için gerekli
import 'package:camera/camera.dart';
// Belge seçimi işlemleri için gerekli
import 'package:flutter_document_picker/flutter_document_picker.dart';
// Resim işleme için gerekli (image_gallery_saver ile uyumlu olması için)
import 'package:image/image.dart' as img;
// Uygulama izinlerini yönetmek için gerekli
import 'package:permission_handler/permission_handler.dart';
// Resimleri galeriye kaydetmek için gerekli
import 'package:image_gallery_saver/image_gallery_saver.dart' as img;
// Renk seçici widget kullanmak için gerekli
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// Galeri görüntüleme ve yönetimi için gerekli
import 'package:photo_manager/photo_manager.dart';
// Key sınıfını ve diğer temel sınıfları kullanmak için gerekli
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: MediaQuery.of(context).size.aspectRatio,
        children: [
          _buildGridItem(context, 'Kamera',
              const Color.fromARGB(255, 235, 89, 16), CameraScreen()),
          _buildGridItem(context, 'Belgeler',
              const Color.fromARGB(255, 141, 57, 224), DocumentsScreen()),
          _buildGridItem(context, 'Galeri',
              const Color.fromARGB(255, 45, 243, 105), GalleryScreen()),
          _buildGridItem(context, 'Ayarlar',
              const Color.fromARGB(255, 52, 90, 224), SettingsScreen()),
        ],
      ),
    );
  }

  Widget _buildGridItem(
      BuildContext context, String title, Color color, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
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
  const CameraScreen({Key? key}) : super(key: key);

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
    // Kameraya erişim izni iste
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      throw Exception('Kamera izni verilmedi.');
    }

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
        title: const Text('Camera'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Kamera hazır ise önizlemeyi göster
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final XFile photo = await _controller.takePicture();
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoPreviewScreen(imagePath: photo.path),
              ),
            );

            if (result != null && !result) {
              await File(photo.path).delete();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => GalleryScreen()),
              );
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
        title: const Text('Photo Preview'),
      ),
      body: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () async {
          await _saveImageToGallery(imagePath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf galeriye kaydedildi.'),
            ),
          );
          Navigator.pop(context, true);
        },
      ),
    );
  }

  Future<void> _saveImageToGallery(String imagePath) async {
    final PermissionStatus permissionStatus =
        await Permission.storage.request(); // Değiştirildi

    if (permissionStatus.isGranted) {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      // Convert the List<int> to Uint8List
      Uint8List uint8ImageBytes = Uint8List.fromList(img.encodeJpg(image!));
      final savedPath = await img.ImageGallerySaver.saveImage(uint8ImageBytes);

      print('Fotoğraf kaydedildi: $savedPath');
    } else {
      throw Exception('Fotoğraf izni verilmedi.');
    }
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Pick a document'),
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

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<AssetEntity>> _assets;

  @override
  void initState() {
    super.initState();
    _assets = _fetchAssets();
  }

  Future<List<AssetEntity>> _fetchAssets() async {
    // Request storage permission
    final storagePermission = await Permission.storage.request();
    if (!storagePermission.isGranted) {
      throw Exception('Storage permission not granted.');
    }

    // Get gallery images
    final List<AssetPathEntity> pathList = await PhotoManager.getAssetPathList(
        onlyAll: true, type: RequestType.image);
    final AssetPathEntity pathEntity = pathList.first;
    final List<AssetEntity> assets =
        await pathEntity.getAssetListPaged(0, pathEntity.assetCount);
    return assets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: FutureBuilder<List<AssetEntity>>(
        future: _assets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              final assets = snapshot.data!;
              return GridView.builder(
                itemCount: assets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return AssetThumbnail(
                      thumbData: assets[index].thumbDataWithSize(200, 200));
                },
              );
            } else {
              return const Center(child: Text('No images found.'));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class AssetThumbnail extends StatelessWidget {
  final Future<Uint8List?> thumbData;

  const AssetThumbnail({Key? key, required this.thumbData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: thumbData,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            return Image.memory(Uint8List.fromList(snapshot.data!),
                fit: BoxFit.cover); // Updated this line
          } else {
            return const Center(child: Text('Error loading thumbnail.'));
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
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
        title: const Text('Settings'),
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
                    title: const Text('Yazı Boyutu'),
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
                        child: const Text('Tamam'),
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
                    title: const Text('Yazı Rengi Seçin'),
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
                        child: const Text('Tamam'),
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
