import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCropScreen extends StatefulWidget {
  final String imagePath;

  const ImageCropScreen({super.key, required this.imagePath});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  Rect? _selection;
  Offset? _startPoint;
  bool _isProcessing = false;

  final GlobalKey _stackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Select Region to Scan',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _startPoint = details.localPosition;
                      _selection = Rect.fromPoints(_startPoint!, _startPoint!);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _selection =
                          Rect.fromPoints(_startPoint!, details.localPosition);
                    });
                  },
                  onPanEnd: (_) {
                    _startPoint = null;
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        key: _stackKey,
                        fit: StackFit.expand,
                        children: [
                          // Image
                          Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          ),

                          // Dark overlay — 4 Positioned containers around selection
                          if (_selection != null) ...[
                            // Top
                            Positioned(
                              left: 0,
                              top: 0,
                              right: 0,
                              height: _selection!.top.clamp(0, constraints.maxHeight),
                              child: Container(color: Colors.black54),
                            ),
                            // Bottom
                            Positioned(
                              left: 0,
                              top: _selection!.bottom.clamp(0, constraints.maxHeight),
                              right: 0,
                              bottom: 0,
                              child: Container(color: Colors.black54),
                            ),
                            // Left
                            Positioned(
                              left: 0,
                              top: _selection!.top.clamp(0, constraints.maxHeight),
                              width: _selection!.left.clamp(0, constraints.maxWidth),
                              height: _selection!.height.abs(),
                              child: Container(color: Colors.black54),
                            ),
                            // Right
                            Positioned(
                              left: _selection!.right.clamp(0, constraints.maxWidth),
                              top: _selection!.top.clamp(0, constraints.maxHeight),
                              right: 0,
                              height: _selection!.height.abs(),
                              child: Container(color: Colors.black54),
                            ),

                            // Selection border
                            Positioned(
                              left: _selection!.left,
                              top: _selection!.top,
                              width: _selection!.width.abs(),
                              height: _selection!.height.abs(),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Floating Submit Button — only shown when area is selected
          if (_selection != null && !_isProcessing)
            Positioned(
              bottom: 30,
              left: 40,
              right: 40,
              child: ElevatedButton.icon(
                onPressed: _cropAndReturn,
                icon: const Icon(Icons.crop, color: Colors.white),
                label: const Text(
                  'Scan Selected Area',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
              ),
            ),

          // Loading indicator while processing
          if (_isProcessing)
            Positioned(
              bottom: 30,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cropAndReturn() async {
    if (_selection == null) return;

    setState(() => _isProcessing = true);

    try {
      // Get the stack's render size
      final RenderBox renderBox =
          _stackKey.currentContext!.findRenderObject() as RenderBox;
      final viewSize = renderBox.size;

      // Load original image
      final bytes = await File(widget.imagePath).readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) throw Exception("Could not decode image");

      // Calculate BoxFit.contain scale & offset
      final double scale = min(
        viewSize.width / originalImage.width,
        viewSize.height / originalImage.height,
      );
      final double drawWidth = originalImage.width * scale;
      final double drawHeight = originalImage.height * scale;
      final double dx = (viewSize.width - drawWidth) / 2;
      final double dy = (viewSize.height - drawHeight) / 2;

      // Map screen coordinates → image pixel coordinates
      final left = (_selection!.left - dx) / scale;
      final top = (_selection!.top - dy) / scale;
      final right = (_selection!.right - dx) / scale;
      final bottom = (_selection!.bottom - dy) / scale;

      final cropX = left.clamp(0.0, originalImage.width.toDouble()).toInt();
      final cropY = top.clamp(0.0, originalImage.height.toDouble()).toInt();
      final cropWidth =
          (right - left).abs().clamp(1.0, (originalImage.width - cropX).toDouble()).toInt();
      final cropHeight =
          (bottom - top).abs().clamp(1.0, (originalImage.height - cropY).toDouble()).toInt();

      // Crop and save
      final cropped = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(targetPath).writeAsBytes(img.encodeJpg(cropped));

      if (mounted) Navigator.pop(context, targetPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }
}
