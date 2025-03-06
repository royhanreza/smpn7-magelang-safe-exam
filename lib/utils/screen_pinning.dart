import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

class ScreenPinningHelper {
  static const MethodChannel _platform = MethodChannel('screen_pinning');
  static bool _isPinned = false;
  static Timer? _timer;

  static void startMonitoring(BuildContext context) {
    _timer?.cancel(); // Hapus timer sebelumnya jika ada

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      bool pinned = await checkPinningStatus();
      if (!pinned && _isPinned) {
        onUnpinned(context);
      }
      _isPinned = pinned;
    });
  }

  static Future<bool> checkPinningStatus() async {
    try {
      return await _platform.invokeMethod('isPinned');
    } on PlatformException {
      return false;
    }
  }

  static Future<void> startPinning() async {
    try {
      await _platform.invokeMethod('startPinning');
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  static Future<bool> isPinned() async {
    try {
      final bool result = await _platform.invokeMethod('isPinned');
      return result;
    } catch (e) {
      print("Error checking screen pinning status: $e");
      return false;
    }
  }

  static void onUnpinned(BuildContext context) {
    print("Aplikasi telah di-unpin!");

    // Keluar dari aplikasi
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    }
    // exit(0);
  }

  static void stopMonitoring() {
    _timer?.cancel();
  }
}
