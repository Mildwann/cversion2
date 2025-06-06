import 'package:cversion2/screens/ready-opencamera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CheckPermission extends StatefulWidget {
  const CheckPermission({super.key});

  @override
  State<CheckPermission> createState() => _CheckPermissionState();
}

class _CheckPermissionState extends State<CheckPermission>
    with WidgetsBindingObserver {
  bool _isRequesting = false;
  bool _permissionDenied = false;
  bool _isPermanentlyDenied = false;
  bool _comingFromSettings = false;
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // กลับหน้า Home เมื่อกลับเข้าแอพใหม่
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
      _permissionDenied = false;
      _isPermanentlyDenied = false;
    });

    final status = await Permission.camera.request();

    setState(() {
      _isRequesting = false;
      _permissionDenied = !status.isGranted;
      _isPermanentlyDenied = status.isPermanentlyDenied;
    });

    if (status.isGranted) {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final result = await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "ReadyOpenCameraDialog",
        barrierColor: Colors.black.withOpacity(0.6), // ฉากหลังโปร่งแสง
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const ReadyOpenCamera(); // ใส่ widget เต็มจอตรงนี้
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      );

      if (result != null) {
        print('Captured image pathssss: $result');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, result);
        }
      });
    }
  }

  void _openAppSettings() async {
    _comingFromSettings = true;
    final opened = await openAppSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเปิดตั้งค่าได้')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Welcome to Camera App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'To start taking photos, please grant camera permission.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Image.asset('assets/images/login.png', height: 200),
              const Spacer(),
              if (_isRequesting)
                const CircularProgressIndicator()
              else if (_permissionDenied)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isPermanentlyDenied
                          ? 'Camera access permanently denied.\nPlease enable it in Settings.'
                          : 'You haven’t granted camera access yet.',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        label: const Text(
                          'Open Settings',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        onPressed: _openAppSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6385f7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Check Permission :)',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}