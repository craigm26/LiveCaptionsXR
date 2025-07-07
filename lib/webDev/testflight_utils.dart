import 'package:url_launcher/url_launcher.dart';

class TestFlightUtils {
  // Replace with actual TestFlight link when available
  static const String testFlightUrl =
      'https://testflight.apple.com/join/YOUR_TESTFLIGHT_CODE';

  static Future<void> openTestFlight() async {
    final Uri url = Uri.parse(testFlightUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to App Store if TestFlight is not available
        await _openAppStore();
      }
    } catch (e) {
      // Fallback to App Store if there's an error
      await _openAppStore();
    }
  }

  static Future<void> _openAppStore() async {
    // Replace with actual App Store link when available
    const String appStoreUrl =
        'https://apps.apple.com/app/livecaptionsxr/id123456789';
    final Uri url = Uri.parse(appStoreUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Handle error - could show a snackbar or dialog
      print('Could not launch TestFlight or App Store: $e');
    }
  }

  static Future<void> openWebsite() async {
    // Link to project website or GitHub
    const String websiteUrl = 'https://github.com/your-username/LiveCaptionsXR';
    final Uri url = Uri.parse(websiteUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Could not launch website: $e');
    }
  }

  static Future<void> openGitHub() async {
    // Link to GitHub repository
    const String githubUrl = 'https://github.com/your-username/LiveCaptionsXR';
    final Uri url = Uri.parse(githubUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Could not launch GitHub: $e');
    }
  }
}
