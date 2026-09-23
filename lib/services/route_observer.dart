import 'package:flutter/material.dart';

/// Registered as a `navigatorObservers` entry on the app's `MaterialApp`
/// (see main.dart) so any screen can subscribe to its own route becoming
/// visible again.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Mix into a `State` to rerun [onReturnedToScreen] every time this screen's
/// route becomes the top route again — not just on first build.
///
/// Screens read from [AppState]'s cached lists (meetings, loans, fines, ...)
/// and only fetch them in `initState`, which Flutter never reruns for a
/// screen still sitting in the navigation stack. So going Dashboard →
/// Meeting Details → Attendance → Record Loan → back left every screen in
/// between showing stale data, no matter how many levels were popped
/// through. `didPopNext` fires on the topmost surviving route regardless of
/// stack depth, which a one-off `await Navigator.push(...); _load();` at an
/// individual call site can't guarantee.
mixin AutoRefreshOnPop<T extends StatefulWidget> on State<T>
    implements RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => onReturnedToScreen();

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  /// Called when a route pushed on top of this screen is popped, returning
  /// here. Implementations should force-refresh their cached [AppState]
  /// data (`refresh: true`) and `setState`.
  void onReturnedToScreen();
}
