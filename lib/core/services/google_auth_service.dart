import 'package:google_sign_in/google_sign_in.dart';

import 'app_logger.dart';

class GoogleAuthService {
  static final AppLogger _logger = AppLogger.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final List<String> _scopes = const [
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  bool _initialized = false;
  GoogleSignInAccount? _currentUser;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _googleSignIn.initialize();
    _initialized = true;
  }

  Future<void> signIn() async {
    await _ensureInitialized();

    try {
      _currentUser = await _googleSignIn.authenticate(scopeHint: _scopes);
      _logger.i('✅ Google Sign-In successful for ${_currentUser?.displayName}');
    } on GoogleSignInException catch (error, stackTrace) {
      _logger.e('❌ Google Sign-In failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
    _currentUser = null;
    _logger.i('✅ Google Sign-Out successful');
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    await _ensureInitialized();

    if (_currentUser == null) {
      await signIn();
    }

    final GoogleSignInAccount? account = _currentUser;
    if (account == null) {
      return null;
    }

    return account.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );
  }
}
