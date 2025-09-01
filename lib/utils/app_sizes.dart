import 'package:flutter/material.dart';

class AppSizes {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;

  static void init(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    _screenWidth = mediaQueryData.size.width;
    _screenHeight = mediaQueryData.size.height;
    _blockSizeHorizontal = _screenWidth / 100;
    _blockSizeVertical = _screenHeight / 100;
  }

  static double width(double percentage) {
    return _blockSizeHorizontal * percentage;
  }

  static double height(double percentage) {
    return _blockSizeVertical * percentage;
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
}
