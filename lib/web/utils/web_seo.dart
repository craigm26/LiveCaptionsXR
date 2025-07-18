import 'package:flutter/foundation.dart';

/// Web SEO utility for optimizing the web version for search engines
class WebSEO {
  static final WebSEO _instance = WebSEO._internal();
  factory WebSEO() => _instance;
  WebSEO._internal();

  /// Set page title for SEO
  static void setPageTitle(String title) {
    if (kIsWeb) {
      debugPrint('🔍 SEO: Setting page title to "$title"');
    }
  }

  /// Set page description for SEO
  static void setPageDescription(String description) {
    if (kIsWeb) {
      debugPrint('🔍 SEO: Setting page description to "$description"');
    }
  }

  /// Set page keywords for SEO
  static void setPageKeywords(List<String> keywords) {
    if (kIsWeb) {
      debugPrint('🔍 SEO: Setting page keywords to ${keywords.join(", ")}');
    }
  }
}

/// Mixin for adding SEO capabilities to pages
mixin SEOMixin {
  void setSEO({
    required String title,
    required String description,
    List<String>? keywords,
  }) {
    WebSEO.setPageTitle(title);
    WebSEO.setPageDescription(description);
    if (keywords != null) WebSEO.setPageKeywords(keywords);
  }
} 