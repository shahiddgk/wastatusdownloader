import 'package:flutter/widgets.dart';

import '../../application/updates/required_update_controller.dart';

/// Keeps system Back from dismissing any route while the update gate is active.
class RequiredUpdateNavigationObserver extends NavigatorObserver {
  RequiredUpdateNavigationObserver(this.controller)
    : _popEntry = _RequiredUpdatePopEntry(!controller.blocksApp) {
    controller.addListener(_onChanged);
  }

  final RequiredUpdateController controller;
  final _RequiredUpdatePopEntry _popEntry;
  final Set<ModalRoute<dynamic>> _routes = {};
  bool _disposed = false;

  void _onChanged() {
    if (!_disposed) _popEntry.canPopNotifier.value = !controller.blocksApp;
  }

  void _register(Route<dynamic>? route) {
    if (!_disposed && route is ModalRoute<dynamic> && _routes.add(route)) {
      route.registerPopEntry(_popEntry);
    }
  }

  void _unregister(Route<dynamic>? route) {
    if (route is ModalRoute<dynamic> && _routes.remove(route)) {
      route.unregisterPopEntry(_popEntry);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _register(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _unregister(oldRoute);
    _register(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _unregister(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _unregister(route);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    controller.removeListener(_onChanged);
    for (final route in _routes.toList()) {
      _unregister(route);
    }
    _popEntry.canPopNotifier.dispose();
  }
}

class _RequiredUpdatePopEntry extends PopEntry<Object?> {
  _RequiredUpdatePopEntry(bool canPop)
    : canPopNotifier = ValueNotifier<bool>(canPop);

  @override
  final ValueNotifier<bool> canPopNotifier;
}
