import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test the hybrid localization method channel
  const channel = MethodChannel('live_captions_xr/hybrid_localization_methods');

  try {
    print('Testing getFusedTransform method...');
    final result =
        await channel.invokeMethod<List<dynamic>>('getFusedTransform');
    print('Success! Got result: $result');
  } catch (e) {
    print('Error: $e');
  }
}
