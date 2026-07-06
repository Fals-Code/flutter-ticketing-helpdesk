import 'package:flutter/foundation.dart';

class StartupGate extends ChangeNotifier {
  bool _minimumRevealComplete = false;

  bool get minimumRevealComplete => _minimumRevealComplete;

  void markRevealComplete() {
    if (_minimumRevealComplete) return;
    _minimumRevealComplete = true;
    _debugStartupLog('minimum reveal complete');
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _minimumRevealComplete = false;
  }
}

final StartupGate startupGate = StartupGate();

void _debugStartupLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}
