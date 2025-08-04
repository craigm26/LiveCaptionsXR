import 'package:google_sign_in/google_sign_in.dart';
import 'app_logger.dart';

class GoogleAuthService {
  static final AppLogger _logger = AppLogger.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  );

  GoogleSignInAccount? _currentUser;

  Future<void> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      _logger.i('✅ Google Sign-In successful for ${_currentUser?.displayName}');
    } catch (error) {
      _logger.e('❌ Google Sign-In failed', error: error);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _logger.i('✅ Google Sign-Out successful');
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    if (_currentUser == null) {
      await signIn();
    }
    return await _currentUser?.authHeaders;
  }
}
