import 'package:flutter/material.dart';

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => ErrorDialog(message: message),
  );
}

void showSuccessDialog(
  BuildContext context,
  String message, {
  VoidCallback? onDismissed,
}) {
  showDialog(
    context: context,
    builder: (context) => SuccessDialog(
      message: message,
      onDismissed: onDismissed,
    ),
  );
}

class ErrorDialog extends StatelessWidget {
  final String message;
  final String? title;
  final String? buttonText;

  const ErrorDialog({
    Key? key,
    required this.message,
    this.title,
    this.buttonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title ?? 'Error',
        style: TextStyle(color: Colors.red),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText ?? 'OK'),
        ),
      ],
    );
  }
}

class SuccessDialog extends StatelessWidget {
  final String message;
  final String? title;
  final String? buttonText;
  final VoidCallback? onDismissed;

  const SuccessDialog({
    Key? key,
    required this.message,
    this.title,
    this.buttonText,
    this.onDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title ?? 'Success',
        style: TextStyle(color: Colors.green),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          SizedBox(height: 16),
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismissed?.call();
          },
          child: Text(buttonText ?? 'OK'),
        ),
      ],
    );
  }
}
