import 'package:flutter/material.dart';

class MyAlertDialog extends StatelessWidget {
  final Widget title;
  final String content;
  final Widget? button;
  final void Function()? onPressed;
  final String text;
  final String? buttonText;

  const MyAlertDialog({
    super.key,
    required this.content,
    required this.title,
    this.button,
    this.onPressed,
    required this.text,

    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: Text(content),
      // you can format FirebaseAuthException for better UX
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text),
        ),
        if (buttonText != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: onPressed,
            child: Text(buttonText!),
          ),
      ],
    );
  }
}
