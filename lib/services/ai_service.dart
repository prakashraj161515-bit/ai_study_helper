import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_config.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final _mainModel = GenerativeModel(
    model: 'gemini-3.1-flash-lite',
    apiKey: getApiKey(),
  );

  final _fallbackModel = GenerativeModel(
    model: 'gemini-2.5-flash-lite',
    apiKey: getApiKey(),
  );

  Future<String> askQuestion(String prompt, {bool detailed = false}) async {
    return await getAnswer(prompt, detailed: detailed);
  }

  Future<String> getAnswer(String prompt, {bool detailed = false}) async {
    try {
      // Try main model with retry logic
      return await _withRetry(() => callGeminiMain(prompt, detailed: detailed));
    } catch (e) {
      // If main fails (even after retry), try fallback
      try {
        return await callGeminiFallback(prompt, detailed: detailed);
      } catch (e2) {
        // Both failed
        throw Exception("Server busy, try again");
      }
    }
  }

  Future<String> _withRetry(Future<String> Function() action) async {
    int retries = 1;
    while (true) {
      try {
        return await action().timeout(const Duration(seconds: 2));
      } catch (e) {
        if (retries <= 0) rethrow;
        retries--;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<String> callGeminiMain(String prompt, {bool detailed = false}) async {
    return _generate(model: _mainModel, prompt: prompt, detailed: detailed);
  }

  Future<String> callGeminiFallback(String prompt, {bool detailed = false}) async {
    return _generate(model: _fallbackModel, prompt: prompt, detailed: detailed);
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

    // Requirement: Use fallback model for MCQs
    final content = [Content.text(prompt)];
    final response = await _fallbackModel.generateContent(content);
    final text = response.text ?? "[]";
    
    try {
      final jsonStr = text.contains("```json") 
        ? text.split("```json")[1].split("```")[0].trim()
        : text.trim();
      return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
    } catch (e) {
      throw Exception("Failed to parse MCQs: $e");
    }
  }
}
