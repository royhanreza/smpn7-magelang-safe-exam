import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:safe_exam/src/view/screen/start_screen.dart';

class RequestDisplayOverAppsPermissionScreen extends StatefulWidget {
  const RequestDisplayOverAppsPermissionScreen({Key? key}) : super(key: key);

  @override
  _RequestDisplayOverAppsPermissionScreenState createState() =>
      _RequestDisplayOverAppsPermissionScreenState();
}

class _RequestDisplayOverAppsPermissionScreenState
    extends State<RequestDisplayOverAppsPermissionScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startOverlayPermissionCheck();
  }

  void _startOverlayPermissionCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (isGranted) {
        _timer?.cancel(); // Hentikan timer jika izin diberikan
        Get.offAll(() => const StartScreen()); // Navigasi ke StartScreen
      }
    });
  }

  Future<void> _grantOverlayPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Izin Diperlukan!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const Text(
              'Aktifkan "Tampilkan Di Atas Aplikasi Lain"',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 10,
            ),
            const Text('Diperlukan untuk menampilkan jendela melayang'),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
                onPressed: () {
                  _grantOverlayPermission();
                },
                child: Text('Aktifkan'))
          ],
        ),
      ),
    ));
  }
}
