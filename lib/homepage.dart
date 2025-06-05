// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:cversion2/screens/checkpermission.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _lastCapturedImagePath;
  double? _imageAspectRatio;

  void _deleteImage() {
    setState(() {
      _lastCapturedImagePath = null;
      _imageAspectRatio = null;
    });
  }

  Future<void> _openDialogCheckPermission() async {
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CheckPermissionDialog",
      pageBuilder: (context, anim1, anim2) {
        return const CheckPermission();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(anim1),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInBack,
                  child: _lastCapturedImagePath != null
                      ? Stack(
                          key: const ValueKey('image_display'),
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: screenWidth * 0.8,
                                height: screenHeight * 0.45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.blue[50],
                                  border: Border.all(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: _imageAspectRatio != null
                                    ? AspectRatio(
                                        aspectRatio: _imageAspectRatio!,
                                        child: Image.file(
                                          File(_lastCapturedImagePath!),
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Image.file(
                                        File(_lastCapturedImagePath!),
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: ClipOval(
                                child: Material(
                                  color: Colors.blue.shade100,
                                  child: InkWell(
                                    splashColor: Colors.blue.withOpacity(0.3),
                                    onTap: _deleteImage,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.close,
                                        size: 24,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          key: const ValueKey('no_image'),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: screenWidth * 0.8,
                                height: screenHeight * 0.45,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    74,
                                    195,
                                    222,
                                    251,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      size: 80,
                                      color: Color(0xff6385f7),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      'Capture the moment',
                                      style: TextStyle(
                                        color: Color(0xff6385f7),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Start your first photo by tapping the button below.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: screenWidth * 0.9,
                height: 65,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xff6385f7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openDialogCheckPermission,
                  child: const Text(
                    'Start camera',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
