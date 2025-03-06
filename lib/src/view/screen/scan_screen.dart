import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe_exam/src/controller/exam_controller.dart';
import 'package:safe_exam/src/view/screen/web_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Barcode? _barcode;
  bool _isProcessing = false;
  final ExamController _examController =
      Get.put<ExamController>(ExamController());
  final MobileScannerController _scannerController = MobileScannerController();

  Future<void> _handleBarcode(BarcodeCapture barcodes) async {
    if (_isProcessing) return; // Cegah proses ganda

    Barcode? barcode = barcodes.barcodes.firstOrNull;
    if (barcode != null && mounted) {
      print('BARCODE CONTENT: ${barcode.displayValue}');

      _isProcessing = true;
      _scannerController.stop(); // Hentikan scanner untuk mencegah scan ulang
      _showLoadingDialog(context);

      try {
        final String? barcodeValue = barcode.displayValue;
        String examUrl =
            await _examController.getExamUrl(token: barcodeValue ?? "INVALID");

        // Tutup dialog sebelum navigasi
        if (mounted) {
          Navigator.pop(context);
        }

        // Navigasi setelah pop (tanpa blink)
        Future.delayed(Duration.zero, () {
          Get.offAll(WebScreen(url: examUrl));
        });
      } catch (e) {
        Get.showSnackbar(GetSnackBar(
          message: e.toString(),
          duration: const Duration(milliseconds: 1500),
        ));
        _isProcessing = false;
        _scannerController.start();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  void dispose() {
    _scannerController
        .dispose(); // Pastikan scanner berhenti saat keluar dari halaman
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = AppBar().preferredSize.height;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double scanBoxSize = 250;
    double scanBoxTop = (screenHeight - scanBoxSize) / 2 - appBarHeight / 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner dengan batas area
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
            scanWindow: Rect.fromLTWH(
              (screenWidth - scanBoxSize) / 2, // Posisi X (Tengah)
              scanBoxTop, // Posisi Y
              scanBoxSize, // Lebar kotak scan
              scanBoxSize, // Tinggi kotak scan
            ),
          ),
          _buildTransparentOverlay(
              screenWidth, screenHeight, scanBoxSize, scanBoxTop),
          _buildCornerLines(screenWidth, scanBoxSize, scanBoxTop),
        ],
      ),
    );
  }

  /// Overlay hitam transparan dengan lubang di tengah
  Widget _buildTransparentOverlay(
      double width, double height, double scanBoxSize, double scanBoxTop) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
              width: width,
              height: height,
              color: Colors.black.withOpacity(0.4)),
          Positioned(
            left: (width - scanBoxSize) / 2,
            top: scanBoxTop,
            child: Container(
                width: scanBoxSize, height: scanBoxSize, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Garis merah di setiap sudut kotak scanner
  Widget _buildCornerLines(
      double width, double scanBoxSize, double scanBoxTop) {
    double cornerSize = 30;
    double thickness = 5;

    return Positioned(
      left: (width - scanBoxSize) / 2,
      top: scanBoxTop,
      child: SizedBox(
        width: scanBoxSize,
        height: scanBoxSize,
        child: Stack(
          children: [
            Positioned(
                left: 0, top: 0, child: _buildCorner(cornerSize, thickness, 0)),
            Positioned(
                right: 0,
                top: 0,
                child: _buildCorner(cornerSize, thickness, 90)),
            Positioned(
                right: 0,
                bottom: 0,
                child: _buildCorner(cornerSize, thickness, 180)),
            Positioned(
                left: 0,
                bottom: 0,
                child: _buildCorner(cornerSize, thickness, 270)),
          ],
        ),
      ),
    );
  }

  /// Widget untuk membangun garis sudut "L"
  Widget _buildCorner(double size, double thickness, double rotation) {
    return Transform.rotate(
      angle: rotation * (3.1415926535 / 180),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned(
                left: 0,
                top: 0,
                child: Container(
                    width: size, height: thickness, color: Colors.red)),
            Positioned(
                left: 0,
                top: 0,
                child: Container(
                    width: thickness, height: size, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  /// Menampilkan dialog loading saat membaca QR
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Membaca QR...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Menutup dialog loading
  void _hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
