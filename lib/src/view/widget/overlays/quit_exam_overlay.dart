import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:safe_exam/core/app_asset.dart';
import 'package:volume_controller/volume_controller.dart';

class QuitExamOverlay extends StatefulWidget {
  const QuitExamOverlay({Key? key}) : super(key: key);

  @override
  _QuitExamOverlayState createState() => _QuitExamOverlayState();
}

class _QuitExamOverlayState extends State<QuitExamOverlay> {
  final String _realFinishCode = "saptacendekia";
  String _finishCode = "";
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final VolumeController _volumeController;
  late final StreamSubscription<double> _subscription;

  double _volumeValue = 0;

  @override
  void initState() {
    super.initState();
    _volumeController = VolumeController.instance;

    _subscription = _volumeController.addListener((volume) {
      setState(() => _volumeValue = volume);
    }, fetchInitialVolume: true);

    setState(() {
      _finishCode = "";
    });
    FlutterOverlayWindow.overlayListener.listen((event) {
      print("Flutter overlay window: $event");
      if (event == "initialize") {
        // Lakukan inisialisasi yang diperlukan untuk overlay
        _playFinishSound();
      }
    });

    // FlutterOverlayWindow.shareData(data)

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _playFinishSound();
    // });
  }

  void _playFinishSound() async {
    await _volumeController.setVolume(1.0);
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer
        .play(AssetSource('sounds/finish_sound.mp3')); // Dari asset
  }

  Future<void> _sendDataToExamScreen() async {
    await FlutterOverlayWindow.shareData("finish");
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _subscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return Focus(
    //   onFocusChange: (hasFocus) async {
    //     if (hasFocus) {
    //       await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    //     } else {
    //       await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    //     }
    //   },
    //   child: Scaffold(
    //     body: SafeArea(
    //       child: Center(
    //         child: Column(
    //           children: [
    //             const TextField(
    //               decoration: InputDecoration(hintText: "Write anything"),
    //             ),
    //             const SizedBox(height: 50.0),
    //             TextButton(
    //               onPressed: () {
    //                 FlutterOverlayWindow.closeOverlay();
    //               },
    //               child: const Text("Close Overlay"),
    //             )
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon(Icons.exit),
                Image.asset(
                  AppAsset.alertIcon,
                  width: 128,
                  cacheWidth: 128,
                ),
                const Text(
                  'Kamu mencoba untuk keluar dari ujian',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                // Text(_volumeValue.toString()),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _finishCode = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Ketik \"$_realFinishCode\" untuk keluar",
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_finishCode == _realFinishCode) {
                        FlutterOverlayWindow.closeOverlay();
                        _audioPlayer.stop();
                        // _audioPlayer.release();

                        _sendDataToExamScreen();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Kode yang kamu masukkan salah"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.exit_to_app, color: Colors.white),
                    label: const Text("Keluar",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Warna tombol merah
                      foregroundColor: Colors.white, // Warna efek saat ditekan
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Sudut tombol melengkung
                      ),
                    ),
                  ),
                ),

                // const SizedBox(height: 50.0),
                // TextButton(
                //   onPressed: () {
                //     FlutterOverlayWindow.closeOverlay();
                //   },
                //   child: const Text("Close Overlay"),
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
