import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ai_service.dart';
import '../services/speech_service.dart';
import '../services/ocr_service.dart';
import 'image_crop_screen.dart';
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
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocr = OCRService();
  
  bool _isLoading = false;
  bool _isListening = false;
  bool _imageProcessed = false;

  @override
  void initState() {
    super.initState();
    _handleInitialMode();
  }

  void _handleInitialMode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mode == InputMode.scan) _pickImage(ImageSource.camera);
      if (widget.mode == InputMode.upload) _pickImage(ImageSource.gallery);
      if (widget.mode == InputMode.voice) _toggleListening();
    });
  }

  void _toggleListening() {
    if (_isListening) {
      NativeSpeech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    NativeSpeech.start((text, isFinal) {
      if (mounted) setState(() => _controller.text = text);
      if (isFinal) {
        NativeSpeech.stop();
        if (mounted) setState(() => _isListening = false);
      }
    }, () {
      if (mounted) setState(() => _isListening = false);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;
    if (!mounted) return;

    final Uint8List? croppedBytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(builder: (context) => ImageCropScreen(imageFile: image)),
    );

    if (croppedBytes == null) return;

    setState(() => _isLoading = true);
    try {
      final text = await AIService().processImage(croppedBytes, prompt: 'Extract all text from this image clearly.');
      setState(() {
        _controller.text = text;
        _isLoading = false;
        _imageProcessed = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Processing Failed: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;

    String fullPrompt;
    String displayQuestion;

    if (_imageProcessed) {
      final hasQuestion = _questionController.text.trim().isNotEmpty;
      if (hasQuestion) {
        // User asked a specific question about the image
        fullPrompt = "The following is text extracted from an image:\n\n${_controller.text}\n\nAnswer this question based on the above content: ${_questionController.text}";
        displayQuestion = _questionController.text;
      } else {
        // No question typed — directly answer whatever is in the image
        fullPrompt = "The following text was extracted from an image. Directly answer or solve the question/problem present in it:\n\n${_controller.text}";
        displayQuestion = _controller.text;
      }
    } else {
      fullPrompt = _controller.text;
      displayQuestion = _controller.text;
    }

    setState(() => _isLoading = true);
    try {
      final state = Provider.of<AppState>(context, listen: false);
      final answer = await state.askQuestion(fullPrompt);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(question: displayQuestion, answer: answer),
          ),
        ).then((_) => setState(() => _isLoading = false));
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
      appBar: AppBar(
        title: Text(widget.mode == InputMode.text ? 'AI Study Assistant' : widget.mode.name.toUpperCase()),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.mode == InputMode.text ? _buildChatView() : _buildDefaultView(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildChatBubble('Hello! How can I help with your studies today?', isAI: true),
        if (_isListening) ...[
          const SizedBox(height: 12),
          _buildChatBubble('Listening...', isAI: true),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickChip('Explain photosynthesis'),
            _buildQuickChip('Solve math equation'),
            _buildQuickChip('Summarize notes'),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.mode == InputMode.scan ? CupertinoIcons.camera_viewfinder : 
            widget.mode == InputMode.upload ? CupertinoIcons.cloud_upload : 
            CupertinoIcons.mic_fill,
            size: 80,
            color: const Color(0xFF2E7D32).withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            widget.mode == InputMode.scan ? 'Scan your notes to get instant help' :
            widget.mode == InputMode.upload ? 'Upload a file for AI analysis' :
            'Speak clearly to ask your question',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 40),
          if (widget.mode == InputMode.scan || widget.mode == InputMode.upload)
            ElevatedButton.icon(
              onPressed: () => _pickImage(widget.mode == InputMode.scan ? ImageSource.camera : ImageSource.gallery),
              icon: const Icon(Icons.add),
              label: Text(widget.mode == InputMode.scan ? 'Open Camera' : 'Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, {bool isAI = true}) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAI ? const Color(0xFFF1F3F4) : const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isAI ? const Radius.circular(0) : const Radius.circular(20),
            bottomRight: isAI ? const Radius.circular(20) : const Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isAI ? Colors.black87 : Colors.white, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
      backgroundColor: const Color(0xFFE8F5E9),
      onPressed: () {
        _controller.text = label;
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_imageProcessed) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _questionController,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2E7D32)),
                  decoration: InputDecoration(
                    hintText: 'What would you like to know about this image?',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF2E7D32)),
                  ),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F3F4), 
                      borderRadius: BorderRadius.circular(24)
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 1,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: _imageProcessed ? 'Extracted text (Editable)...' : 'Ask anything...', 
                        border: InputBorder.none, 
                        hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey)
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F3F4)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                      color: _isListening ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _submit,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
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
