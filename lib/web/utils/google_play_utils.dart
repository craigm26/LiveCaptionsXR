import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/interaction_handler.dart';

class GooglePlayUtils {
  // Google Play Beta link for testing
  static const String googlePlayBetaUrl =
      'https://play.google.com/apps/testing/com.livecaptionsxr.app';

  static Future<void> openGooglePlayBeta() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse(googlePlayBetaUrl);
        await _launchUrlWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> _launchUrlWithTimeout(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      await _openGooglePlayStore();
    }
  }

  static Future<void> _openGooglePlayStore() async {
    // Update with Google Play Store link when published
    const String googlePlayUrl =
        'https://play.google.com/store/apps/details?id=com.livecaptionsxr.app';
    final Uri url = Uri.parse(googlePlayUrl);

    try {
      await Future.any([
        _launchGooglePlayWithTimeout(url),
        Future.delayed(const Duration(seconds: 5))
      ]);
    } catch (e) {
      // Handle error - could show a snackbar or dialog
      print('Could not launch Google Play Beta or Store: $e');
    }
  }

  static Future<void> _launchGooglePlayWithTimeout(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }
} 