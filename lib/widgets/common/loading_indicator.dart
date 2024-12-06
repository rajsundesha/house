import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool overlay;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.overlay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loading = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        if (message != null) ...[
          SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
    );

    if (overlay) {
      return Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: loading,
          ),
        ),
      );
    }

    return Center(child: loading);
  }
}
