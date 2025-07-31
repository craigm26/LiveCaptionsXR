import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/interaction_handler.dart';

class GitHubDocsUtils {
  static const String baseRepoUrl = 'https://github.com/craigm26/livecaptionsxr';
  
  // Documentation folder paths
  static const String docsFolder = '/tree/main/docs';
  static const String prdFolder = '/tree/main/prd';
  static const String readmeFile = '/blob/main/README.md';
  static const String contributingFile = '/blob/main/CONTRIBUTING.md';
  static const String developmentGuideFile = '/blob/main/DEVELOPMENT_GUIDE.md';

  static Future<void> openDocsFolder() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse('$baseRepoUrl$docsFolder');
        await _launchUrlWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> openPRDFolder() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse('$baseRepoUrl$prdFolder');
        await _launchUrlWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> openReadme() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse('$baseRepoUrl$readmeFile');
        await _launchUrlWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> openContributingGuide() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse('$baseRepoUrl/blob/main/CONTRIBUTING.md');
        await _launchUrlWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> openDevelopmentGuide() async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse('$baseRepoUrl/blob/main/docs/SETUP_GUIDE.md');
        await _launchUrlWithTimeout(url);
      },
      timeout: const Duration(seconds: 5),
    );
  }

  static Future<void> openSpecificDoc(String docPath) async {
    return InteractionHandler.safeAsyncExecution(
      action: () async {
        final Uri url = Uri.parse('$baseRepoUrl/blob/main/$docPath');
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
      throw Exception('Could not launch URL: $url');
    }
  }
} 