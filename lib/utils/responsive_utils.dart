// lib/core/responsive/context_ext.dart
import 'package:flutter/widgets.dart';

extension ContextResponsive on BuildContext {
  bool get isTab => MediaQuery.of(this).size.width >= 600;
  bool get isMobile => MediaQuery.of(this).size.width < 600;

  // Adaptive font size
  double adaptSize(double mobile, {double? tab, double? max}) {
    double size = isTab? (tab ?? mobile ) : mobile;
    if (max != null && size > max) return max;
    return size;
  }

  // Adaptive  padding
  double adaptPadding(double mobile, {double? tab, double? max}) {
    double value = isTab ? (tab ?? mobile ) : mobile;
    if (max != null && value > max) value = max;
    return value;
  }
}
