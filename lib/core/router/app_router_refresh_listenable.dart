import 'dart:async';
import 'package:flutter/material.dart';

/// Utility class to convert a Stream into a Listenable for GoRouter's refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(
    Stream<dynamic> stream, {
    Iterable<Listenable> listenables = const [],
  }) : _listenables = listenables.toList(growable: false) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
    for (final listenable in _listenables) {
      listenable.addListener(notifyListeners);
    }
  }

  late final StreamSubscription<dynamic> _subscription;
  final List<Listenable> _listenables;

  @override
  void dispose() {
    for (final listenable in _listenables) {
      listenable.removeListener(notifyListeners);
    }
    _subscription.cancel();
    super.dispose();
  }
}
