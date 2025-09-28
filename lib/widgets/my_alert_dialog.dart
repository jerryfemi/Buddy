import 'package:flutter/material.dart';

class MyAlertDialog extends StatelessWidget {
  final Widget title;
  final String content;

  const MyAlertDialog({super.key, required this.content, required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: Text(content),
      // you can format FirebaseAuthException for better UX
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
