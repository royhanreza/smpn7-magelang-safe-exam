import 'package:flutter/material.dart';
import 'package:safe_exam/src/view/widget/battery_level.dart';
import 'package:safe_exam/src/view/widget/clock_time.dart';

class CustomStatusBar extends StatelessWidget {
  const CustomStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: const BoxDecoration(color: Colors.black),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClockTime(),
          BatteryLevel(),
        ],
      ),
    );
  }
}
