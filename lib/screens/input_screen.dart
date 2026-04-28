import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ocr_service.dart';
import 'result_screen.dart';

enum InputMode { scan, upload, text, voice }

class InputScreen extends StatefulWidget {
  final InputMode mode;
  const InputScreen({super.key, required this.mode});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocr = OCRService();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _handleInitialMode();
  }

  void _handleInitialMode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mode == InputMode.scan) _pickImage(ImageSource.camera);
      if (widget.mode == InputMode.upload) _pickImage(ImageSource.gallery);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final text = await _ocr.recognizeText(image);
        setState(() {
          _controller.text = text;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        _showError("Processing Failed: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final state = Provider.of<AppState>(context, listen: false);
      final answer = await state.askQuestion(_controller.text);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              question: _controller.text,
              answer: answer,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.name.toUpperCase())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Enter or paste your study question here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Consumer<AppState>(
                builder: (context, state, child) {
                  final bool isOffline = state.isOffline;
                  return ElevatedButton(
                    onPressed: (_isLoading || isOffline) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOffline ? Colors.grey : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isOffline ? 'No Internet' : 'Ask AI',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _ocr.dispose();
    super.dispose();
  }
}
