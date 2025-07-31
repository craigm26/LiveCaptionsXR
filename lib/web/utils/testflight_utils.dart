import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/interaction_handler.dart';

class TestFlightUtils {
  // TestFlight link for beta testing
  static const String testFlightUrl =
      'https://testflight.apple.com/join/pyxZEWFh';

  static Future<void> openTestFlight() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse(testFlightUrl);
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
      await _openAppStore();
    }
  }

  static Future<void> _openAppStore() async {
    // Update with App Store link when published
    const String appStoreUrl =
        'https://apps.apple.com/app/live-captions-xr/id123456789';
    final Uri url = Uri.parse(appStoreUrl);

    try {
      await Future.any([
        _launchAppStoreWithTimeout(url),
        Future.delayed(const Duration(seconds: 5))
      ]);
    } catch (e) {
      // Handle error - could show a snackbar or dialog
      print('Could not launch TestFlight or App Store: $e');
    }
  }

  static Future<void> _launchAppStoreWithTimeout(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  static Future<void> openWebsite(String s) async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        const String websiteUrl = 'https://github.com/craigm26/livecaptionsxr';
        final Uri url = Uri.parse(websiteUrl);
        await _launchWebsiteWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> _launchWebsiteWithTimeout(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  static Future<void> openGitHub() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        const String githubUrl = 'https://github.com/craigm26/livecaptionsxr';
        final Uri url = Uri.parse(githubUrl);
        await _launchGitHubWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> _launchGitHubWithTimeout(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
