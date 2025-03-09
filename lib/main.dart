import 'dart:io' show File;
import 'dart:typed_data'; // สำหรับ bytes บนเว็บ
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// -----------------------------------------------------------------------------
// 1) Main: เริ่มโปรแกรมหลัก
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เรียกดูรายการกล้องทั้งหมดก่อน runApp
  final cameras = await availableCameras();

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Polaroid Camera',
      theme: ThemeData(
        // กำหนด Theme หลักให้ออกแนว Minimal
        fontFamily: 'sans-serif',
        primaryColor: Colors.pinkAccent,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

// -----------------------------------------------------------------------------
// 2) Model CapturedImage: เก็บภาพถ่าย (File สำหรับมือถือ / Bytes สำหรับเว็บ)
// -----------------------------------------------------------------------------
class CapturedImage {
  final File? file;
  final Uint8List? bytes;

  CapturedImage({this.file, this.bytes});

  bool get isWeb => bytes != null;
}

// -----------------------------------------------------------------------------
// 3) หน้า Home
// -----------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<CapturedImage> _photos = [];

  // เปิดหน้า Camera เพื่อถ่ายรูป
  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(cameras: widget.cameras),
      ),
    );

    if (result != null && result is CapturedImage) {
      setState(() {
        _photos.add(result);
      });
    }
  }

  // ลบรูป
  void _deletePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ทำพื้นหลัง Gradient โทน ชมพู-ฟ้าอ่อน พาสเทล
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFDEE9), // ชมพูอ่อน
              Color(0xFFB5FFFC), // ฟ้าอ่อน
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // หัว Minimal Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Minimal Polaroid Camera',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              // ส่วนแสดงรูป
              Expanded(
                child: _photos.isEmpty
                    ? Center(
                        child: Text(
                          'ยังไม่มีรูปภาพ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: List.generate(_photos.length, (index) {
                            final img = _photos[index];
                            return PolaroidImage(
                              image: img,
                              onDelete: () => _deletePhoto(index),
                            );
                          }),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.camera_alt),
        onPressed: _openCamera,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4) Widget PolaroidImage: แสดงรูปในกรอบโพลารอยด์ + ปุ่มลบ
// -----------------------------------------------------------------------------
class PolaroidImage extends StatelessWidget {
  final CapturedImage image;
  final VoidCallback onDelete;

  const PolaroidImage({
    Key? key,
    required this.image,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double size = 150; // ความกว้างของรูป
    const double totalHeight = 200; // ความสูงรวมของกรอบ

    // สร้าง widget รูปภาพ (File หรือ Memory)
    Widget photoWidget;
    if (image.isWeb) {
      photoWidget = Image.memory(
        image.bytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      photoWidget = Image.file(
        image.file!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: size,
      height: totalHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0), // มุมโค้งเล็กน้อย
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // รูปภาพเต็มพื้นที่ด้านบน เหลือด้านล่างไว้ 30px
          Positioned.fill(
            top: 0,
            bottom: 30,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: photoWidget,
            ),
          ),

          // พื้นที่สีขาวด้านล่าง (เหมือนโพลารอยด์)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 30,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),

          // ปุ่มลบ (X) มุมขวาบน
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5) หน้า CameraScreen: เปิดกล้อง ถ่ายรูป
// -----------------------------------------------------------------------------
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // เลือกกล้องหน้า ถ้ามี
      final frontCamera = widget.cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => widget.cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isInitialized || _controller == null) return;
    try {
      final xfile = await _controller!.takePicture();

      CapturedImage captured;
      if (kIsWeb) {
        // บนเว็บ => readAsBytes
        final bytes = await xfile.readAsBytes();
        captured = CapturedImage(bytes: bytes);
      } else {
        // บนมือถือ => File
        final file = File(xfile.path);
        captured = CapturedImage(file: file);
      }

      Navigator.pop(context, captured);
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Preview'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Container(
        // Gradient โทนฟ้า-ชมพูพาสเทล (กลับกันเล็กน้อย)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB5FFFC),
              Color(0xFFFFDEE9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isInitialized
            ? Stack(
                children: [
                  CameraPreview(_controller!),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: FloatingActionButton(
                        backgroundColor: Colors.pinkAccent,
                        onPressed: _capturePhoto,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
