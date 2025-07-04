import 'package:camera/camera.dart';
import 'package:cversion2/screens/camera-on/opencamera.dart';
import 'package:flutter/material.dart';

class ReadyOpenCamera extends StatefulWidget {
  const ReadyOpenCamera({super.key});

  @override
  State<ReadyOpenCamera> createState() => _ReadyOpenCameraState();
}

class _ReadyOpenCameraState extends State<ReadyOpenCamera> with WidgetsBindingObserver {
  late Future<List<CameraDescription>> _camerasFuture;

  @override
  void initState() {
    super.initState();
    _camerasFuture = availableCameras();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // กลับหน้า Home เมื่อกลับเข้าแอพใหม่
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: FutureBuilder<List<CameraDescription>>(
        future: _camerasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading cameras: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No cameras found'));
          }

          final cameras = snapshot.data!;

          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/picture.png',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Get Ready!',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2a2a2a),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Are you ready to open the camera and capture amazing moments?',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xff555555),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          
                          if (Navigator.canPop(context)) {
                            Navigator.of(context, rootNavigator: true).pop("ready-open-camera");
                          }
                        },
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text(
                          'Open Camera',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff6385f7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}