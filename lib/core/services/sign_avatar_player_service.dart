import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Shared local server for the sign avatar viewer.
///
/// The avatar player is used by multiple screens, so the WebView should point
/// at a single local HTTP server rather than spinning up a separate server per
/// screen.
class SignAvatarPlayerService {
  SignAvatarPlayerService._();

  static final SignAvatarPlayerService instance =
      SignAvatarPlayerService._();

  static const int _port = 8080;

  final InAppLocalhostServer _server =
      InAppLocalhostServer(documentRoot: 'assets', port: _port);

  /// Cached so concurrent callers all await the *same* start, instead of each
  /// racing to call [InAppLocalhostServer.start] (which throws "already
  /// started" if invoked twice before the async port bind completes).
  Future<void>? _startFuture;

  Uri get viewerUri => Uri.parse('http://localhost:$_port/sign_player.html');

  Future<void> ensureStarted() => _startFuture ??= _start();

  Future<void> _start() async {
    if (_server.isRunning()) return;
    try {
      await _server.start();
    } catch (e) {
      // The port is already bound (e.g. a previous server survived hot reload).
      // Anything else is a genuine failure worth surfacing.
      if (!e.toString().contains('already started')) {
        _startFuture = null; // allow a later retry
        rethrow;
      }
    }
  }

  bool get isRunning => _server.isRunning();
}
