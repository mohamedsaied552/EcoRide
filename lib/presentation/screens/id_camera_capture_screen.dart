import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:glider/core/utils/image_processing.dart';

enum IdSide { front, back }

class IdCameraCaptureScreen extends StatefulWidget {
  const IdCameraCaptureScreen({required this.side, super.key});

  final IdSide side;

  @override
  State<IdCameraCaptureScreen> createState() => _IdCameraCaptureScreenState();
}

class _IdCameraCaptureScreenState extends State<IdCameraCaptureScreen> {
  CameraController? _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitUp,
    ]);
    _init();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    await controller.setFlashMode(FlashMode.auto);
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
                _Stencil(
                  label: widget.side == IdSide.front
                      ? 'Align front of ID within the frame'
                      : 'Align back of ID within the frame',
                ),
                Positioned(
                  bottom: 48,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

class _Stencil extends StatelessWidget {
  const _Stencil({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * 0.95;
        final h = w / 1.4;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Positioned(
              top: (constraints.maxHeight / 2) + (h / 2) + 16,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
