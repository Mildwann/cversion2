import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cversion2/screens/camera-on/camera-settings-panel.dart';
import 'package:cversion2/screens/camera-on/preview-image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';


class FullPageDialog extends StatefulWidget {
  final List<CameraDescription> cameras;
  const FullPageDialog({super.key, required this.cameras});

  @override
  State<FullPageDialog> createState() => _FullPageDialogState();
}

class _FullPageDialogState extends State<FullPageDialog> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  XFile? _capturedImage;

  ResolutionPreset _selectedResolution = ResolutionPreset.high;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermissionAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (mounted) {
        Navigator.of(context).pop(_capturedImage?.path);
      }
    }
  }

  Future<void> _checkCameraPermissionAndInit() async {
    final status = await Permission.camera.status;
    if (!status.isGranted && !(await Permission.camera.request()).isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่ได้รับสิทธิ์เข้าถึงกล้อง')),
      );
      Navigator.of(context).pop();
      return;
    }
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    final camera = widget.cameras[_selectedCameraIndex];
    _controller = CameraController(camera, _selectedResolution, enableAudio: false);

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    setState(() => _isCameraInitialized = false);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;

    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 33) return (await Permission.photos.request()).isGranted;
      if (sdkInt >= 30) return (await Permission.manageExternalStorage.request()).isGranted;
      return (await Permission.storage.request()).isGranted;
    } else if (Platform.isIOS) {
      return (await Permission.photosAddOnly.request()).isGranted;
    }
    return false;
  }

  Future<void> _onSaveImage(String imagePath) async {
    if (await _requestStoragePermission()) {
      try {
        final result = await ImageGallerySaverPlus.saveFile(imagePath);
        print('Image saved: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ภาพถูกบันทึกเรียบร้อยแล้ว')),
          );
        }
      } catch (e) {
        print('Error saving image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่ได้รับสิทธิ์จัดเก็บรูปภาพ')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;

    try {
      final picture = await _controller!.takePicture();

      if (!mounted) return;
      setState(() => _capturedImage = picture);

      final result = await showImagePreviewDialog(context, picture.path);

      if (result == 'ok') {
        await _onSaveImage(picture.path);
        if (mounted) Navigator.pop(context, picture.path);
      } else if (result == 'retake') {
        setState(() => _capturedImage = null);
        await _initializeCamera();
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _closeCamera() => Navigator.pop(context, _capturedImage?.path);

  void _openSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CameraSettingsPanel(
        currentResolution: _selectedResolution,
        onResolutionChanged: (res) async {
          setState(() {
            _selectedResolution = res;
            _isCameraInitialized = false;
          });
          await _controller?.dispose();
          await _initializeCamera();
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: topPadding),
          _buildTopBar(),
          Expanded(child: _buildCameraPreview()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() => Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _closeCamera,
              child: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const Text(
              'Camera',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: _openSettingsPanel,
              child: const Icon(Icons.settings, color: Colors.white, size: 28),
            ),
          ],
        ),
      );

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      children: [
        CameraPreview(_controller!),
        if (_capturedImage != null)
          Positioned(
            bottom: 120,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 28),
              onPressed: _switchCamera,
            ),
            GestureDetector(
              onTap: _takePicture,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 28),
          ],
        ),
      );
}
