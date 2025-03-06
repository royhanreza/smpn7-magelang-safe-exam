import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:safe_exam/core/app_asset.dart';
import 'package:safe_exam/src/view/screen/exam_screen.dart';
import 'package:safe_exam/src/view/screen/request_display_over_apps_permission_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  static const _platform = MethodChannel('screen_pinning');
  bool _isPinned = false;
  Timer? _timer;

  // Bluetooth
  bool _isBluetoothActive = false;
  bool _isBluetoothChecked = false;
  bool _isCheckBluetoothLoading = false;

  // Floating Apps
  bool _isFloatingAppsInstalled = false;
  bool _isFloatingAppsChecked = false;
  bool _isCheckFloatingAppsLoading = false;

  // Emulator
  bool _isRunningOnEmulator = false;
  bool _isRunningOnEmulatorChecked = false;
  bool _isCheckRunningOnEmulatorLoading = false;

  // Pinned
  bool _isCheckPinningLoading = false;

  bool get _isCheckingLoading =>
      _isCheckBluetoothLoading ||
      _isCheckFloatingAppsLoading ||
      _isCheckRunningOnEmulatorLoading ||
      _isCheckPinningLoading;

  bool get _isAllRequirementChecked =>
      _isBluetoothChecked &&
      _isFloatingAppsChecked &&
      _isRunningOnEmulatorChecked;

  bool get _isRequirementSatisfied =>
      !_isBluetoothActive && !_isFloatingAppsInstalled && !_isRunningOnEmulator;

  Future<void> _checkBluetoothStatus() async {
    setState(() {
      _isCheckBluetoothLoading = true;
    });
    // await Future.delayed(const Duration(milliseconds: 500));

    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;

    setState(() {
      _isBluetoothActive = state == BluetoothAdapterState.on;
      _isBluetoothChecked = true;
      _isCheckBluetoothLoading = false;
    });
  }

  Future<bool?> _isAppInstalled(String packageName) async {
    try {
      bool? installed = await InstalledApps.isAppInstalled(packageName);
      return installed;
    } catch (e) {
      return false;
    }
  }

  // Check Floating App Installed
  Future<void> _checkFloatingAppsInstalled() async {
    setState(() {
      _isCheckFloatingAppsLoading = true;
    });
    // await Future.delayed(const Duration(milliseconds: 500));

    const String floatingAppsPackageName = "com.lwi.android.flapps";
    bool? isFloatingAppsInstalled =
        await _isAppInstalled(floatingAppsPackageName);

    setState(() {
      _isFloatingAppsInstalled = isFloatingAppsInstalled ?? false;
      _isFloatingAppsChecked = true;
      _isCheckFloatingAppsLoading = false;
    });
  }

  Future<bool> _getIsRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final isEmulator = androidInfo.isPhysicalDevice == false ||
          androidInfo.model.contains("sdk") ||
          androidInfo.hardware.contains("goldfish") ||
          androidInfo.hardware.contains("ranchu") ||
          androidInfo.fingerprint.contains("generic");

      return isEmulator;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice; // Jika `false`, berarti emulator
    }

    return false; // Default untuk platform lain
  }

// Check is running on emulator
  Future<void> _checkIsRunningOnEmulator() async {
    setState(() {
      _isCheckRunningOnEmulatorLoading = true;
    });

    // await Future.delayed(const Duration(milliseconds: 500));
    bool isRunningOnEmulator = await _getIsRunningOnEmulator();

    setState(() {
      _isRunningOnEmulator = isRunningOnEmulator;
      _isRunningOnEmulatorChecked = true;
      _isCheckRunningOnEmulatorLoading = false;
    });
  }

  Future<void> _checkStartingRequirement() async {
    setState(() {
      _isBluetoothChecked = false;
      _isFloatingAppsChecked = false;
      _isRunningOnEmulatorChecked = false;
    });
    await _checkBluetoothStatus();
    await _checkFloatingAppsInstalled();
    await _checkIsRunningOnEmulator();

    if (_isRequirementSatisfied) {
      setState(() {
        _isCheckPinningLoading = true;
      });

      bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isGranted) {
        Get.to(const RequestDisplayOverAppsPermissionScreen());
        return;
      }

      await startPinning();

      setState(() {
        _isCheckPinningLoading = false;
      });
    }
  }

  Future<void> startPinning() async {
    try {
      await _platform.invokeMethod('startPinning');
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  void startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      bool pinned = await checkPinningStatus();
      if (!pinned && _isPinned) {
        onUnpinned();
      }
      setState(() {
        _isPinned = pinned;
      });
    });
  }

  Future<bool> checkPinningStatus() async {
    try {
      return await _platform.invokeMethod('isPinned');
    } on PlatformException {
      return false;
    }
  }

  void onUnpinned() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Peringatan"),
        content: const Text("Aplikasi keluar dari mode pinned."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: const Color.fromRGBO(144, 202, 249, 1),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
                child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppAsset.smpn7Magelang,
                        width: 150,
                        cacheWidth: 300,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Column(
                        children: [
                          Text(
                            'ADAB',
                            style: GoogleFonts.archivoBlack(
                                fontWeight: FontWeight.bold, fontSize: 32),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Text(
                              'Anjungan Digital Asesmen Belajar',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500, fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Expanded(
                                child: Row(
                              children: [
                                Icon(
                                  Icons.bluetooth,
                                  color: Colors.black54,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'Nonaktifkan Bluetooth',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            )),
                            _isCheckBluetoothLoading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _isBluetoothChecked
                                    ? _isBluetoothActive
                                        ? Icon(
                                            Icons.cancel,
                                            color: Colors.red.shade400,
                                          )
                                        : const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                    : Container(),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Expanded(
                                child: Row(
                              children: [
                                Icon(
                                  Icons.web_outlined,
                                  color: Colors.black54,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'Tidak memasang Floating Apps',
                                  style: TextStyle(color: Colors.black54),
                                )
                              ],
                            )),
                            _isCheckFloatingAppsLoading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _isFloatingAppsChecked
                                    ? _isFloatingAppsInstalled
                                        ? Icon(
                                            Icons.cancel,
                                            color: Colors.red.shade400,
                                          )
                                        : const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                    : Container(),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Expanded(
                                child: Row(
                              children: [
                                Icon(
                                  Icons.computer,
                                  color: Colors.black54,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'Tidak menggunakan emulator',
                                  style: TextStyle(color: Colors.black54),
                                )
                              ],
                            )),
                            _isCheckRunningOnEmulatorLoading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _isRunningOnEmulatorChecked
                                    ? _isRunningOnEmulator
                                        ? Icon(
                                            Icons.cancel,
                                            color: Colors.red.shade400,
                                          )
                                        : const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                    : Container(),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _isPinned &&
                              _isAllRequirementChecked &&
                              _isRequirementSatisfied
                          ? Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton(
                                        style: ButtonStyle(
                                          padding: const WidgetStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                  vertical: 15)),
                                          backgroundColor:
                                              const WidgetStatePropertyAll(
                                                  Colors.black),
                                          foregroundColor:
                                              const WidgetStatePropertyAll(
                                                  Colors.white),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          bool isGranted =
                                              await FlutterOverlayWindow
                                                  .isPermissionGranted();
                                          if (!isGranted) {
                                            Get.to(
                                                const RequestDisplayOverAppsPermissionScreen());
                                          } else {
                                            Get.off(const ExamScreen());
                                          }
                                        },
                                        child: const Row(
                                          mainAxisSize: MainAxisSize
                                              .min, // Hindari tombol terlalu lebar
                                          children: [
                                            Text(
                                              'Mulai',
                                              style: TextStyle(fontSize: 15),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward),
                                          ],
                                        )))
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton(
                                  style: ButtonStyle(
                                    padding: const WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(vertical: 15)),
                                    backgroundColor:
                                        const WidgetStatePropertyAll(
                                            Colors.black),
                                    foregroundColor:
                                        const WidgetStatePropertyAll(
                                            Colors.white),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    _isCheckingLoading
                                        ? null
                                        : _checkStartingRequirement();
                                  },
                                  child:
                                      // Row(
                                      //   mainAxisSize: MainAxisSize
                                      //       .min, // Hindari tombol terlalu lebar
                                      //   children: [
                                      //     Text(
                                      //       'Mulai',
                                      //       style: TextStyle(fontSize: 15),
                                      //     ),
                                      //     SizedBox(width: 8),
                                      //     Icon(Icons.arrow_forward),
                                      //   ],
                                      // )
                                      _isCheckingLoading
                                          ? SizedBox(
                                              child: LoadingAnimationWidget
                                                  .progressiveDots(
                                                      color: Colors.white,
                                                      size: 24))
                                          : const Row(
                                              mainAxisSize: MainAxisSize
                                                  .min, // Hindari tombol terlalu lebar
                                              children: [
                                                Text(
                                                  'Periksa',
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(Icons.checklist_sharp),
                                              ],
                                            ),
                                ))
                              ],
                            )
                    ],
                  )
                ],
              ),
            ))
          ],
        ),
      ),
    ));
  }
}
