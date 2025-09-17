import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Color.fromARGB(255, 23, 23, 23),
    primary: Color.fromARGB(255, 28, 100, 218),
    secondary: Color.fromARGB(20, 116, 116, 128),
    tertiary: Colors.grey,
    tertiaryContainer: Colors.grey.shade300,
    inversePrimary: Colors.grey.shade100,
  ),
  textTheme: Typography.whiteCupertino,
);
