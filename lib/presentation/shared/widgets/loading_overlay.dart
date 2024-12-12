import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? color;
  final double opacity;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.color,
    this.opacity = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [child];

    if (isLoading) {
      widgetList.add(
        Positioned.fill(
          child: Container(
            color: (color ?? Colors.black).withOpacity(opacity),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  if (message != null) ...[
                    SizedBox(height: 16),
                    Text(
                      message!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: widgetList,
    );
  }
}
