import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BatteryLevel extends StatefulWidget {
  const BatteryLevel({Key? key}) : super(key: key);

  @override
  State<BatteryLevel> createState() => _BatteryLevelState();
}

class _BatteryLevelState extends State<BatteryLevel> {
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
    _startBatteryListener();
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });
  }

  // Update level baterai setiap 10 detik
  void _startBatteryListener() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _getBatteryLevel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hentikan timer saat screen ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2,
          height: 10,
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))),
        ),
        const SizedBox(
          width: 2,
        ),
        Container(
          width: 40, // Parent lebih besar
          height: 20,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _batteryLevel / 100, // 50% dari parent
                heightFactor: 1, // 50% dari parent
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: _batteryLevel >= 20
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  _batteryLevel.toString(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 8,
                      color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
