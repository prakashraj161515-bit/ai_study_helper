import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_config.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Single model configuration as requested
  final _model = GenerativeModel(
    model: 'gemini-3.1-flash-lite-preview', 
    apiKey: getApiKey(),
    tools: [
      Tool(googleSearchRetrieval: GoogleSearchRetrieval())
    ],
  );

  Future<String> askQuestion(String prompt, {bool detailed = false}) async {
    return await getAnswer(prompt, detailed: detailed);
  }

  Future<String> getAnswer(String prompt, {bool detailed = false}) async {
    try {
      // Try the single model with retry logic
      return await _withRetry(() => _generate(model: _model, prompt: prompt, detailed: detailed));
    } catch (e) {
      print("AI Error: $e");
      throw Exception("Server busy, try again");
    }
  }

  Future<String> _withRetry(Future<String> Function() action) async {
    int retries = 1;
    while (true) {
      try {
        return await action().timeout(const Duration(seconds: 15));
      } catch (e) {
        if (retries <= 0) rethrow;
        retries--;
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
  }

  Future<String> _generate({
    required GenerativeModel model,
    required String prompt,
    bool detailed = false,
  }) async {
    final systemPrompt = detailed 
      ? "Provide a detailed explanation. Answer in the same language as the question."
      : "Keep answer short and clear. No unnecessary explanation. Answer in the same language as the question.";
    
    final content = [Content.text("$systemPrompt\n\nQuestion: $prompt")];
    final response = await model.generateContent(content);
    return response.text ?? "No response from AI.";
  }

  Future<List<Map<String, dynamic>>> generateMCQs(String topic, {int count = 3, String difficulty = 'easy'}) async {
    final prompt = """
      Generate $count $difficulty MCQs about: $topic.
      Format the output as a JSON list of objects.
      Each object must have:
      - "question": string
      - "options": list of 4 strings
      - "correctIndex": integer (0-3)
      - "explanation": string
      Rules: Short questions, 4 options, 1 correct answer.
      Answer in the same language as the topic.
    """;

    final content = [Content.text(prompt)];
    // Using the same single model for MCQs
    final response = await _model.generateContent(content);
    final text = response.text ?? "[]";
    
    try {
      final jsonStr = text.contains("```json") 
        ? text.split("```json")[1].split("```")[0].trim()
        : text.trim();
      return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
    } catch (e) {
      throw Exception("Failed to generate MCQs: $e");
    }
  }
}
