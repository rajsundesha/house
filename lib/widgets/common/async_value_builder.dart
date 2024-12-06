//lib/widgets/common/async_value_builder.dart
import 'package:flutter/material.dart';

class AsyncValueBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;

  const AsyncValueBuilder({
    Key? key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorBuilder?.call(snapshot.error.toString()) ??
              Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return loadingWidget ?? Center(child: CircularProgressIndicator());
        }

        return builder(snapshot.data as T);
      },
    );
  }
}
