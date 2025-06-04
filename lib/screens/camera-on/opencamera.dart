import 'dart:io';
import 'package:cversion2/screens/camera-on/camera-settings-panel.dart';
import 'package:cversion2/screens/camera-on/preview-image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';


class FullPageDialog extends StatefulWidget {
  final List<CameraDescription> cameras;
  const FullPageDialog({super.key, required this.cameras});

  @override
  State<FullPageDialog> createState() => _FullPageDialogState();
}

class _FullPageDialogState extends State<FullPageDialog>   with WidgetsBindingObserver{
  CameraController? _controller;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  XFile? _capturedImage;

  ResolutionPreset selectedResolution = ResolutionPreset.high;
  double selectedAspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    // _initializeCamera();
     WidgetsBinding.instance.addObserver(this);
    _checkCameraPermissionAndInit();
  }
  
   @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // เมื่อแอพถูกสลับไป background หรือ inactive ให้ปิด dialog
      if (mounted) {
        Navigator.of(context).pop(_capturedImage?.path);
      }
    }
  }

  Future<void> _checkCameraPermissionAndInit() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่ได้รับสิทธิ์เข้าถึงกล้อง')),
        );
        Navigator.of(context).pop();
        return;
      }
    }
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _controller = CameraController(
      widget.cameras[_selectedCameraIndex],
      selectedResolution,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Camera init error: $e');
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        var photosPermission = await Permission.photos.request();
        return photosPermission.isGranted;
      } else if (sdkInt >= 30) {
        var mediaPermission = await Permission.manageExternalStorage.request();
        return mediaPermission.isGranted;
      } else {
        var storagePermission = await Permission.storage.request();
        return storagePermission.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      return status.isGranted;
    }
    return false;
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    setState(() {
      _isCameraInitialized = false;
    });

    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;

    await _controller?.dispose();

    await _initializeCamera();
  }

  Future<void> _onSaveImage(String imagePath) async {
    bool granted = await requestStoragePermission();
    if (granted) {
      try {
        final result = await ImageGallerySaverPlus.saveFile(imagePath);
        print("Saved to gallery: $result");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ภาพถูกบันทึกลงในคลังรูปภาพเรียบร้อยแล้ว')),
        );
      } catch (e) {
        print("Error saving image: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่ได้รับสิทธิ์ในการเข้าถึงพื้นที่จัดเก็บ')),
      );
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;

    try {
      final XFile picture = await _controller!.takePicture();
      final imageFile = File(picture.path);
      final decodedImage = await decodeImageFromList(await imageFile.readAsBytes());
      print('Captured Image Size: ${decodedImage.width} x ${decodedImage.height}');

      await _controller?.dispose();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        _capturedImage = picture;
      });

      final result = await showImagePreviewDialog(context, picture.path);

      if (result == 'ok') {
        await _onSaveImage(picture.path);
        if (!mounted) return;
        Navigator.pop(context, picture.path);
      } else if (result == 'retake') {
        if (!mounted) return;
        setState(() {
          _capturedImage = null;
        });
        await _initializeCamera();
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _closeCamera() {
    Navigator.pop(context, _capturedImage?.path);
  }

  void _openSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CameraSettingsPanel(
          currentResolution: selectedResolution,
          onResolutionChanged: (val) async {
            setState(() {
              selectedResolution = val;
              _isCameraInitialized = false;
            });
            await _controller?.dispose();
            await _initializeCamera();

            if (mounted) Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: topPadding),
          Container(
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
          ),
          Expanded(
            child: _isCameraInitialized
                ? Stack(
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
                              child: Image.file(
                                File(_capturedImage!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
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
          ),
        ],
      ),
    );
  }
}