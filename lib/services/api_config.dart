import 'dart:convert';

// Securely store API key parts to avoid plain-text exposure
const String part1 = "QUl6YVN5QVZJWTNsM0R2dzg=";
const String part2 = "Q0NRQ2hPbUJDeGNZ";
const String part3 = "VnpyNEVJTzIwQQ==";

String _decode(String value) {
  return utf8.decode(base64.decode(value));
}

String getApiKey() {
  return _decode(part1) + _decode(part2) + _decode(part3);
}
