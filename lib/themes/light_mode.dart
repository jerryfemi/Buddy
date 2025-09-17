import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Color.fromARGB(255, 229, 229, 234),
    primary: Color.fromARGB(255, 76, 145, 255),
    secondary: Color.fromARGB(20, 116, 116, 128),
    tertiary: Colors.grey.shade600,
    tertiaryContainer: Colors.grey.shade800,
    inversePrimary: Colors.grey.shade900,
  ),
  textTheme: Typography.blackCupertino,
);
