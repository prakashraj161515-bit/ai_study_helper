import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

// All 8 drag handles: 4 corners + 4 mid-sides
enum _Handle { none, topLeft, topRight, bottomLeft, bottomRight, top, bottom, left, right }

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

  static const double _hitRadius = 28.0;
  static const double _cornerSize = 18.0;
  static const double _sideHandleSize = 36.0;
  static const double _sideHandleThickness = 8.0;

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

  Rect _normalizeRect(Rect r) => Rect.fromLTRB(
        min(r.left, r.right),
        min(r.top, r.bottom),
        max(r.left, r.right),
        max(r.top, r.bottom),
      );

  _Handle _hitTestHandles(Offset p) {
    if (_selection == null) return _Handle.none;
    final s = _normalizeRect(_selection!);
    final midX = (s.left + s.right) / 2;
    final midY = (s.top + s.bottom) / 2;

    // Corners first (priority)
    if ((p - s.topLeft).distance < _hitRadius) return _Handle.topLeft;
    if ((p - s.topRight).distance < _hitRadius) return _Handle.topRight;
    if ((p - s.bottomLeft).distance < _hitRadius) return _Handle.bottomLeft;
    if ((p - s.bottomRight).distance < _hitRadius) return _Handle.bottomRight;

    // Mid-sides
    if ((p - Offset(midX, s.top)).distance < _hitRadius) return _Handle.top;
    if ((p - Offset(midX, s.bottom)).distance < _hitRadius) return _Handle.bottom;
    if ((p - Offset(s.left, midY)).distance < _hitRadius) return _Handle.left;
    if ((p - Offset(s.right, midY)).distance < _hitRadius) return _Handle.right;

    return _Handle.none;
  }

  void _onPanStart(DragStartDetails d) {
    final handle = _hitTestHandles(d.localPosition);
    if (handle != _Handle.none) {
      setState(() => _activeHandle = handle);
    } else {
      setState(() {
        _activeHandle = _Handle.none;
        _startPoint = d.localPosition;
        _selection = Rect.fromPoints(_startPoint!, _startPoint!);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_activeHandle != _Handle.none && _selection != null) {
      final s = _normalizeRect(_selection!);
      setState(() {
        switch (_activeHandle) {
          case _Handle.topLeft:
            _selection = Rect.fromLTRB(d.localPosition.dx, d.localPosition.dy, s.right, s.bottom);
            break;
          case _Handle.topRight:
            _selection = Rect.fromLTRB(s.left, d.localPosition.dy, d.localPosition.dx, s.bottom);
            break;
          case _Handle.bottomLeft:
            _selection = Rect.fromLTRB(d.localPosition.dx, s.top, s.right, d.localPosition.dy);
            break;
          case _Handle.bottomRight:
            _selection = Rect.fromLTRB(s.left, s.top, d.localPosition.dx, d.localPosition.dy);
            break;
          case _Handle.top:
            _selection = Rect.fromLTRB(s.left, d.localPosition.dy, s.right, s.bottom);
            break;
          case _Handle.bottom:
            _selection = Rect.fromLTRB(s.left, s.top, s.right, d.localPosition.dy);
            break;
          case _Handle.left:
            _selection = Rect.fromLTRB(d.localPosition.dx, s.top, s.right, s.bottom);
            break;
          case _Handle.right:
            _selection = Rect.fromLTRB(s.left, s.top, d.localPosition.dx, s.bottom);
            break;
          case _Handle.none:
            break;
        }
      });
    } else if (_startPoint != null) {
      setState(() => _selection = Rect.fromPoints(_startPoint!, d.localPosition));
    }
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _startPoint = null;
      _activeHandle = _Handle.none;
      if (_selection != null) _selection = _normalizeRect(_selection!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayRect = _selection != null ? _normalizeRect(_selection!) : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Select Area to Scan',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => _submitFullImage(),
            child: const Text('Skip Crop',
                style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loadingImage
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Stack(
              children: [
                // Image + gesture area
                Positioned.fill(
                  bottom: 110,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Stack(
                        key: _stackKey,
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.contain),

                          if (displayRect != null) ...[
                            // Dimming overlays
                            _buildDim(Offset.zero, Size(constraints.maxWidth, displayRect.top)),
                            _buildDim(Offset(0, displayRect.bottom),
                                Size(constraints.maxWidth, constraints.maxHeight - displayRect.bottom)),
                            _buildDim(Offset(0, displayRect.top),
                                Size(displayRect.left, displayRect.height)),
                            _buildDim(Offset(displayRect.right, displayRect.top),
                                Size(constraints.maxWidth - displayRect.right, displayRect.height)),

                            // Green border
                            Positioned(
                              left: displayRect.left,
                              top: displayRect.top,
                              width: displayRect.width,
                              height: displayRect.height,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF2E7D32), width: 2.5),
                                ),
                                child: Stack(children: [
                                  // Grid lines (rule of thirds)
                                  CustomPaint(
                                    painter: _GridPainter(),
                                    size: Size(displayRect.width, displayRect.height),
                                  ),
                                ]),
                              ),
                            ),

                            // Corner handles (L-shaped)
                            _buildCornerHandle(displayRect.topLeft, true, true),
                            _buildCornerHandle(displayRect.topRight, false, true),
                            _buildCornerHandle(displayRect.bottomLeft, true, false),
                            _buildCornerHandle(displayRect.bottomRight, false, false),

                            // Mid-side handles
                            _buildSideHandle(Offset((displayRect.left + displayRect.right) / 2, displayRect.top), true),
                            _buildSideHandle(Offset((displayRect.left + displayRect.right) / 2, displayRect.bottom), true),
                            _buildSideHandle(Offset(displayRect.left, (displayRect.top + displayRect.bottom) / 2), false),
                            _buildSideHandle(Offset(displayRect.right, (displayRect.top + displayRect.bottom) / 2), false),
                          ],
                        ],
                      );
                    }),
                  ),
                ),

                // Hint text
                if (displayRect == null)
                  Positioned(
                    top: 20, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Drag to select area for scanning',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    ),
                  ),

                // Bottom action bar
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Processing image...', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              // Submit Full Image
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _submitFullImage,
                                  icon: const Icon(CupertinoIcons.doc_text_fill, size: 16),
                                  label: const Text('Use Full Image', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Crop & Scan
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: displayRect != null ? _cropAndReturn : null,
                                  icon: const Icon(Icons.crop, size: 18),
                                  label: const Text('Crop & Scan',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[700],
                                    disabledForegroundColor: Colors.white38,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDim(Offset offset, Size size) {
    if (size.width <= 0 || size.height <= 0) return const SizedBox.shrink();
    return Positioned(
      left: offset.dx, top: offset.dy,
      width: size.width, height: size.height,
      child: Container(color: Colors.black.withOpacity(0.55)),
    );
  }

  // L-shaped corner handle
  Widget _buildCornerHandle(Offset center, bool isLeft, bool isTop) {
    const len = 22.0;
    const thick = 4.0;
    const c = Color(0xFF2E7D32);
    return Positioned(
      left: isLeft ? center.dx - thick : center.dx - len,
      top: isTop ? center.dy - thick : center.dy - len,
      width: len + thick,
      height: len + thick,
      child: Stack(children: [
        // Horizontal bar
        Positioned(
          left: isLeft ? 0 : 0,
          top: isTop ? 0 : len - thick,
          width: len + thick,
          height: thick,
          child: Container(color: c),
        ),
        // Vertical bar
        Positioned(
          left: isLeft ? 0 : len - thick,
          top: isTop ? 0 : 0,
          width: thick,
          height: len + thick,
          child: Container(color: c),
        ),
      ]),
    );
  }

  // Rectangular mid-side handle
  Widget _buildSideHandle(Offset center, bool isHorizontal) {
    return Positioned(
      left: center.dx - (isHorizontal ? _sideHandleSize / 2 : _sideHandleThickness / 2),
      top: center.dy - (isHorizontal ? _sideHandleThickness / 2 : _sideHandleSize / 2),
      width: isHorizontal ? _sideHandleSize : _sideHandleThickness,
      height: isHorizontal ? _sideHandleThickness : _sideHandleSize,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Future<void> _submitFullImage() async {
    if (_imageBytes == null) return;
    Navigator.pop(context, _imageBytes);
  }

  Future<void> _cropAndReturn() async {
    if (_selection == null || _decodedImage == null || _imageBytes == null) return;
    setState(() => _isProcessing = true);
    try {
      final RenderBox renderBox = _stackKey.currentContext!.findRenderObject() as RenderBox;
      final viewSize = renderBox.size;
      final originalImage = _decodedImage!;
      final s = _normalizeRect(_selection!);

      final double scale = min(
        viewSize.width / originalImage.width,
        viewSize.height / originalImage.height,
      );
      final double drawWidth = originalImage.width * scale;
      final double drawHeight = originalImage.height * scale;
      final double dx = (viewSize.width - drawWidth) / 2;
      final double dy = (viewSize.height - drawHeight) / 2;

      final left = (s.left - dx) / scale;
      final top = (s.top - dy) / scale;
      final right = (s.right - dx) / scale;
      final bottom = (s.bottom - dy) / scale;

      final cropX = left.clamp(0.0, originalImage.width.toDouble()).toInt();
      final cropY = top.clamp(0.0, originalImage.height.toDouble()).toInt();
      final cropWidth = (right - left).clamp(1.0, (originalImage.width - cropX).toDouble()).toInt();
      final cropHeight = (bottom - top).clamp(1.0, (originalImage.height - cropY).toDouble()).toInt();

      final cropped = img.copyCrop(originalImage, x: cropX, y: cropY, width: cropWidth, height: cropHeight);
      final croppedBytes = Uint8List.fromList(img.encodeJpg(cropped));

      if (mounted) Navigator.pop(context, croppedBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }
}

// Rule-of-thirds grid painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 0.8;

    // 2 vertical lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    // 2 horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
