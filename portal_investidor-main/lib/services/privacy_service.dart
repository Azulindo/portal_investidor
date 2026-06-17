import 'package:flutter/foundation.dart';

class PrivacyService extends ChangeNotifier {
  bool _isMasked = true;

  bool get isMasked => _isMasked;

  void toggleMask() {
    _isMasked = !_isMasked;
    notifyListeners();
  }

  String maskValue(String value) {
    return _isMasked ? '****' : value;
  }

  String maskCurrency(double value) {
    return _isMasked ? '**** €' : '${value.toStringAsFixed(2)} €';
  }
}
