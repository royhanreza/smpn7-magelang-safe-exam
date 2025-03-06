import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockTime extends StatefulWidget {
  const ClockTime({Key? key}) : super(key: key);

  @override
  _ClockTimeState createState() => _ClockTimeState();
}

class _ClockTimeState extends State<ClockTime> {
  late Stream<String> _timeStream;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(const Duration(seconds: 1), (_) {
      return DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // const Icon(
        //   Icons.access_time_sharp,
        //   color: Colors.white,
        //   size: 16,
        // ),
        StreamBuilder<String>(
          stream: _timeStream,
          initialData: DateFormat('HH:mm:ss').format(DateTime.now()),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        )
      ],
    );
  }
}
