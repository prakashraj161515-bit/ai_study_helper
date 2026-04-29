import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

// Which corner handle is being dragged
enum _Handle { none, topLeft, topRight, bottomLeft, bottomRight }

class ImageCropScreen extends StatefulWidget {
  final XFile imageFile;

  const ImageCropScreen({super.key, required this.imageFile});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  Rect? _selection;
  Offset? _startPoint;
  bool _isProcessing = false;
  _Handle _activeHandle = _Handle.none;

  Uint8List? _imageBytes;
  img.Image? _decodedImage;
  bool _loadingImage = true;

  final GlobalKey _stackKey = GlobalKey();

  // How far from a corner handle the tap can be to count as a handle drag
  static const double _handleHitRadius = 24.0;
  static const double _handleSize = 14.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    setState(() {
      _imageBytes = bytes;
      _decodedImage = decoded;
      _loadingImage = false;
    });
  }

  /// Returns which handle (corner) the user tapped on, or none
  _Handle _hitTestHandles(Offset point) {
    if (_selection == null) return _Handle.none;
    final s = _normalizeRect(_selection!);

    if ((point - s.topLeft).distance < _handleHitRadius) return _Handle.topLeft;
    if ((point - s.topRight).distance < _handleHitRadius) return _Handle.topRight;
    if ((point - s.bottomLeft).distance < _handleHitRadius) return _Handle.bottomLeft;
    if ((point - s.bottomRight).distance < _handleHitRadius) return _Handle.bottomRight;

    return _Handle.none;
  }

  /// Ensures left < right and top < bottom
  Rect _normalizeRect(Rect r) => Rect.fromLTRB(
        min(r.left, r.right),
        min(r.top, r.bottom),
        max(r.left, r.right),
        max(r.top, r.bottom),
      );

  @override
  Widget build(BuildContext context) {
    final displayRect =
        _selection != null ? _normalizeRect(_selection!) : null;

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
      body: _loadingImage
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Main gesture + image area
                Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onPanStart: (details) {
                          final handle =
                              _hitTestHandles(details.localPosition);
                          if (handle != _Handle.none) {
                            // User tapped a corner handle — resize mode
                            setState(() => _activeHandle = handle);
                          } else {
                            // User tapped outside — start fresh selection
                            setState(() {
                              _activeHandle = _Handle.none;
                              _startPoint = details.localPosition;
                              _selection = Rect.fromPoints(
                                  _startPoint!, _startPoint!);
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          if (_activeHandle != _Handle.none &&
                              _selection != null) {
                            // Resize by moving the active corner
                            final s = _normalizeRect(_selection!);
                            setState(() {
                              switch (_activeHandle) {
                                case _Handle.topLeft:
                                  _selection = Rect.fromLTRB(
                                      details.localPosition.dx,
                                      details.localPosition.dy,
                                      s.right,
                                      s.bottom);
                                  break;
                                case _Handle.topRight:
                                  _selection = Rect.fromLTRB(
                                      s.left,
                                      details.localPosition.dy,
                                      details.localPosition.dx,
                                      s.bottom);
                                  break;
                                case _Handle.bottomLeft:
                                  _selection = Rect.fromLTRB(
                                      details.localPosition.dx,
                                      s.top,
                                      s.right,
                                      details.localPosition.dy);
                                  break;
                                case _Handle.bottomRight:
                                  _selection = Rect.fromLTRB(
                                      s.left,
                                      s.top,
                                      details.localPosition.dx,
                                      details.localPosition.dy);
                                  break;
                                case _Handle.none:
                                  break;
                              }
                            });
                          } else {
                            // Drawing new selection
                            setState(() {
                              _selection = Rect.fromPoints(
                                  _startPoint!, details.localPosition);
                            });
                          }
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _startPoint = null;
                            _activeHandle = _Handle.none;
                            // Normalize on end so handles are always correct
                            if (_selection != null) {
                              _selection = _normalizeRect(_selection!);
                            }
                          });
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              key: _stackKey,
                              fit: StackFit.expand,
                              children: [
                                // Image (Web-safe: Image.memory)
                                Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.contain,
                                ),

                                // Semi-dark overlay — 4 containers around selection
                                if (displayRect != null) ...[
                                  // Top
                                  Positioned(
                                    left: 0, top: 0, right: 0,
                                    height: displayRect.top
                                        .clamp(0, constraints.maxHeight),
                                    child: Container(color: Colors.black54),
                                  ),
                                  // Bottom
                                  Positioned(
                                    left: 0,
                                    top: displayRect.bottom
                                        .clamp(0, constraints.maxHeight),
                                    right: 0, bottom: 0,
                                    child: Container(color: Colors.black54),
                                  ),
                                  // Left
                                  Positioned(
                                    left: 0,
                                    top: displayRect.top
                                        .clamp(0, constraints.maxHeight),
                                    width: displayRect.left
                                        .clamp(0, constraints.maxWidth),
                                    height: displayRect.height,
                                    child: Container(color: Colors.black54),
                                  ),
                                  // Right
                                  Positioned(
                                    left: displayRect.right
                                        .clamp(0, constraints.maxWidth),
                                    top: displayRect.top
                                        .clamp(0, constraints.maxHeight),
                                    right: 0,
                                    height: displayRect.height,
                                    child: Container(color: Colors.black54),
                                  ),

                                  // Blue border around selection
                                  Positioned(
                                    left: displayRect.left,
                                    top: displayRect.top,
                                    width: displayRect.width,
                                    height: displayRect.height,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.blue,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Corner handles
                                  _buildHandle(displayRect.topLeft),
                                  _buildHandle(displayRect.topRight),
                                  _buildHandle(displayRect.bottomLeft),
                                  _buildHandle(displayRect.bottomRight),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating "Scan Selected Area" button
                if (displayRect != null && !_isProcessing)
                  Positioned(
                    bottom: 30, left: 40, right: 40,
                    child: ElevatedButton.icon(
                      onPressed: _cropAndReturn,
                      icon: const Icon(Icons.crop, color: Colors.white),
                      label: const Text(
                        'Scan Selected Area',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                      ),
                    ),
                  ),

                // Processing indicator
                if (_isProcessing)
                  Positioned(
                    bottom: 30, left: 40, right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Blue square handle at a corner position
  Widget _buildHandle(Offset center) {
    return Positioned(
      left: center.dx - _handleSize / 2,
      top: center.dy - _handleSize / 2,
      width: _handleSize,
      height: _handleSize,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Future<void> _cropAndReturn() async {
    if (_selection == null || _decodedImage == null || _imageBytes == null)
      return;

    setState(() => _isProcessing = true);

    try {
      final RenderBox renderBox =
          _stackKey.currentContext!.findRenderObject() as RenderBox;
      final viewSize = renderBox.size;

      final originalImage = _decodedImage!;
      final s = _normalizeRect(_selection!);

      // BoxFit.contain scale & offset
      final double scale = min(
        viewSize.width / originalImage.width,
        viewSize.height / originalImage.height,
      );
      final double drawWidth = originalImage.width * scale;
      final double drawHeight = originalImage.height * scale;
      final double dx = (viewSize.width - drawWidth) / 2;
      final double dy = (viewSize.height - drawHeight) / 2;

      // Screen coords → image pixels
      final left = (s.left - dx) / scale;
      final top = (s.top - dy) / scale;
      final right = (s.right - dx) / scale;
      final bottom = (s.bottom - dy) / scale;

      final cropX = left.clamp(0.0, originalImage.width.toDouble()).toInt();
      final cropY = top.clamp(0.0, originalImage.height.toDouble()).toInt();
      final cropWidth = (right - left)
          .clamp(1.0, (originalImage.width - cropX).toDouble())
          .toInt();
      final cropHeight = (bottom - top)
          .clamp(1.0, (originalImage.height - cropY).toDouble())
          .toInt();

      // Crop in memory — no file I/O (works on Web!)
      final cropped = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final croppedBytes = Uint8List.fromList(img.encodeJpg(cropped));

      if (mounted) Navigator.pop(context, croppedBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }
}
