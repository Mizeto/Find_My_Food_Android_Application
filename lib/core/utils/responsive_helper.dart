import 'package:flutter/material.dart';

class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  // Reference design dimensions (e.g., iPhone 11/Pixel 4)
  static const double refWidth = 375;
  static const double refHeight = 812;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    _blockSizeHorizontal = screenWidth / 100;
    _blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }

  /// Scale width based on screen width
  static double w(double width) {
    return (width / refWidth) * screenWidth;
  }

  /// Scale height based on screen height
  static double h(double height) {
    return (height / refHeight) * screenHeight;
  }

  /// Scale font size based on screen width (maintaining readability)
  static double sp(double fontSize) {
    return (fontSize / refWidth) * screenWidth;
  }

  /// Get vertical spacing
  static double setHeight(double height) => (height / refHeight) * screenHeight;

  /// Get horizontal spacing
  static double setWidth(double width) => (width / refWidth) * screenWidth;

  /// Scale based on the smaller dimension (useful for square elements)
  static double scale(double size) {
    double scaleFactor = screenWidth < screenHeight 
        ? screenWidth / refWidth 
        : screenHeight / refHeight;
    return size * scaleFactor;
  }
}

// Extension for easier usage
extension ResponsiveDouble on num {
  double get w => ResponsiveHelper.w(toDouble());
  double get h => ResponsiveHelper.h(toDouble());
  double get sp => ResponsiveHelper.sp(toDouble());
  double get scale => ResponsiveHelper.scale(toDouble());
}
