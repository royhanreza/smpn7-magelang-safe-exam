import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safe_exam/core/app_asset.dart';
import 'package:safe_exam/src/controller/exam_controller.dart';
import 'package:safe_exam/src/view/screen/scan_screen.dart';
import 'package:safe_exam/src/view/widget/battery_level.dart';
import 'package:safe_exam/src/view/widget/bootstrap_alert.dart';
import 'package:safe_exam/src/view/widget/clock_time.dart';
import 'package:safe_exam/src/view/widget/custom_status_bar.dart';
import 'package:safe_exam/src/view/widget/exam/exam_code.dart';
import 'package:safe_exam/utils/screen_pinning.dart';
import 'package:volume_controller/volume_controller.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({Key? key}) : super(key: key);

  @override
  _ExamScreenState createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  String getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "🌅 Selamat Pagi!";
    } else if (hour >= 12 && hour < 15) {
      return "🌞 Selamat Siang!";
    } else if (hour >= 15 && hour < 18) {
      return "🌇 Selamat Sore!";
    } else {
      return "🌙 Selamat Malam!";
    }
  }

  @override
  void initState() {
    super.initState();
    ScreenPinningHelper.startMonitoring(context);
    _grantOverlayPermission();
  }

  Future<void> _grantOverlayPermission() async {
    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    print('overlay granted status: $isGranted');
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  @override
  void dispose() {
    ScreenPinningHelper.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color.fromRGBO(144, 202, 249, 1),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        // Pindahkan ke sini
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // Sesuaikan dengan konten
                          children: [
                            Image.asset(
                              AppAsset.studentLearning,
                              height: 200,
                              cacheHeight: 600,
                            ),
                            Text(
                              getGreetingMessage(),
                              style: GoogleFonts.poppins(
                                  fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Jangan lupa untuk bersiap dan berdoa sebelum memulai ujian',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.openSans(),
                              ),
                            ),
                            // const SizedBox(
                            //   height: 10,
                            // ),
                            // const BootstrapAlert(
                            //   message:
                            //       "Jangan unpin aplikasi sebelum menyelesaikan ujian",
                            //   type: "info",
                            //   dismissible: false,
                            // ),
                            const SizedBox(height: 40),

                            // Tombol Scan QR
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ButtonStyle(
                                      padding: const WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(vertical: 15)),
                                      backgroundColor:
                                          const WidgetStatePropertyAll(
                                              Color.fromARGB(
                                                  255, 35, 112, 175)),
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
                                    onPressed: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const ScanScreen()));
                                    },
                                    icon: const Icon(Icons.qr_code),
                                    label: const Text(
                                      'Scan QR',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Atau',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const ExamCode(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Custom Status Bar tetap di bagian bawah
            // const Align(
            //   alignment: Alignment.bottomCenter,
            //   child: CustomStatusBar(),
            // ),
          ],
        ),
      ),
    );
  }
}
