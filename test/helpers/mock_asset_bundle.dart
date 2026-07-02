import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stubs the `flutter/assets` asset bundle so tests can serve in-memory
/// asset payloads without touching the real filesystem.
void setMockAssetBundle(Map<String, String> assets) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        final asset = assets[key];
        if (asset == null) {
          return null;
        }
        return ByteData.view(Uint8List.fromList(utf8.encode(asset)).buffer);
      });
}

/// Removes the `flutter/assets` stub installed by [setMockAssetBundle].
void clearMockAssetBundle() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
}
