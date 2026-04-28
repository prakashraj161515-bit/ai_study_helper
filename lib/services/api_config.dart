import 'dart:convert';

const String part1 = "QUl6YVN5QVZJWTNsM0Q=";
const String part2 = "dnc4Q0NRQ2hPbUJDeA==";
const String part3 = "Y1Z6cjRFSU8yMEE=";

// DeepSeek config (placeholder)
const String DEEPSEEK_API_KEY = "YOUR_DEEPSEEK_API_KEY";
const String DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions";

String _decode(String value) {
  return utf8.decode(base64.decode(value));
}

String getApiKey() {
  return _decode(part1) + _decode(part2) + _decode(part3);
}
