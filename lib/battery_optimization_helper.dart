import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';

class BatteryOptimizationHelper {
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final sdkInt = info.version.sdkInt;

      if (sdkInt >= 23) {
        final intent = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
        await intent.launch();
      }
    }
  }
}
