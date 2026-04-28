import 'dart:js' as js;

class NativeSpeech {
  static void start(Function(String, bool) onResult, Function() onEnd) {
    if (!js.context.hasProperty('startSpeech')) return;

    js.context['onSpeechResult'] = (String text, bool isFinal) {
      onResult(text, isFinal);
    };

    js.context['onSpeechEnd'] = () {
      onEnd();
    };

    js.context.callMethod('startSpeech');
  }

  static void stop() {
    if (js.context.hasProperty('stopSpeech')) {
      js.context.callMethod('stopSpeech');
    }
  }
}
