import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:glider/core/utils/image_processing.dart';

class SelfieCameraCaptureScreen extends StatefulWidget {
  const SelfieCameraCaptureScreen({super.key});

  @override
  State<SelfieCameraCaptureScreen> createState() => _SelfieCameraCaptureScreenState();
}

class _SelfieCameraCaptureScreenState extends State<SelfieCameraCaptureScreen> {
  CameraController? _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _init();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    try {
      await controller.setFlashMode(FlashMode.auto);
    } catch (_) {
      // front cam may not support flash on some devices
    }
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      final raw = await file.readAsBytes();
      final processed = ImageProcessing.process(raw);
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(processed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                const _OvalStencil(),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _capture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.black26, width: 4),
                        ),
                        child: _busy
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _OvalStencil extends StatelessWidget {
  const _OvalStencil();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * 0.7;
        final h = constraints.maxHeight * 0.45;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.5 + h / 2 + 16,
              child: const Text(
                'Place your face inside the oval',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
