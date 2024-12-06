import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppState {
  initial,
  authenticated,
  unauthenticated
}

final appStateProvider = StateProvider<AppState>((ref) => AppState.initial);