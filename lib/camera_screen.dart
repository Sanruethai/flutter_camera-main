// lib/camera_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    // ดึงรายการกล้องทั้งหมด
    cameras = await availableCameras();
    // เลือกกล้องหน้าเป็นค่าเริ่มต้น (ถ้าไม่มีจะใช้กล้องตัวแรกที่เจอ)
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // สร้าง controller
    controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false, // ถ้าไม่ต้องการบันทึกเสียง
    );

    try {
      // เริ่มต้น controller
      await controller?.initialize();
      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> capturePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      // ถ่ายรูป
      final XFile file = await controller!.takePicture();

      // สร้าง File object จาก path
      File imageFile = File(file.path);

      // ส่งไฟล์กลับไปยังหน้าเดิมผ่าน Navigator
      Navigator.pop(context, imageFile);
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ถ่ายรูปด้วยกล้องหน้า'),
      ),
      body: isCameraInitialized
          ? Stack(
              children: [
                // แสดงตัวอย่างกล้อง
                CameraPreview(controller!),
                // ปุ่มถ่ายรูป
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FloatingActionButton(
                      child: Icon(Icons.camera_alt),
                      onPressed: capturePhoto,
                    ),
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
