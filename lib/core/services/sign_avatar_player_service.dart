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

  final InAppLocalhostServer _server =
      InAppLocalhostServer(documentRoot: 'assets', port: 8080);

  Uri get viewerUri => Uri.parse('http://localhost:8080/sign_player.html');

  Future<void> ensureStarted() async {
    if (!_server.isRunning()) {
      await _server.start();
    }
  }

  bool get isRunning => _server.isRunning();
}