import 'dart:async';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_timezone/flutter_timezone.dart'; // <<<--- CHANGED THIS LINE

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _timezone = 'Unknown';
  List<String> _availableTimezones = <String>[];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      _timezone =
          await FlutterTimezone.getLocalTimezone(); // <<<--- CHANGED THIS LINE
    } catch (e) {
      print('Could not get the local timezone');
    }
    try {
      _availableTimezones =
          await FlutterTimezone.getAvailableTimezones(); // <<<--- CHANGED THIS LINE
      _availableTimezones.sort();
    } catch (e) {
      print('Could not get available timezones');
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Local timezone app')),
        body: Column(
          children: <Widget>[
            Text('Local timezone: $_timezone\n'),
            Text('Available timezones:'),
            Expanded(
              child: ListView.builder(
                itemCount: _availableTimezones.length,
                itemBuilder: (_, index) => Text(_availableTimezones[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
