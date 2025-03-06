import 'package:flutter/material.dart';

class BootstrapAlert extends StatefulWidget {
  final String message;
  final String type;
  final bool dismissible;

  const BootstrapAlert({
    Key? key,
    required this.message,
    this.type = "info",
    this.dismissible = true,
  }) : super(key: key);

  @override
  _BootstrapAlertState createState() => _BootstrapAlertState();
}

class _BootstrapAlertState extends State<BootstrapAlert> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return SizedBox.shrink();

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (widget.type) {
      case "success":
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case "danger":
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        break;
      case "warning":
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.warning;
        break;
      case "info":
      default:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            if (widget.dismissible)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isVisible = false;
                  });
                },
                child: Icon(Icons.close, color: textColor),
              ),
          ],
        ),
      ),
    );
  }
}
