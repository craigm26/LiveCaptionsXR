//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_gemma/FlutterGemmaPlugin.h>)
#import <flutter_gemma/FlutterGemmaPlugin.h>
#else
@import flutter_gemma;
#endif

#if __has_include(<gemma3n_multimodal/Gemma3nMultimodalPlugin.h>)
#import <gemma3n_multimodal/Gemma3nMultimodalPlugin.h>
#else
@import gemma3n_multimodal;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<large_file_handler/LargeFileHandlerPlugin.h>)
#import <large_file_handler/LargeFileHandlerPlugin.h>
#else
@import large_file_handler;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterGemmaPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterGemmaPlugin"]];
  [Gemma3nMultimodalPlugin registerWithRegistrar:[registry registrarForPlugin:@"Gemma3nMultimodalPlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [LargeFileHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"LargeFileHandlerPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
