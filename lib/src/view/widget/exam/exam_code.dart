import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:safe_exam/src/controller/exam_controller.dart';
import 'package:safe_exam/src/view/screen/web_screen.dart';

class ExamCode extends StatefulWidget {
  const ExamCode({super.key});

  @override
  _ExamCodeState createState() => _ExamCodeState();
}

class _ExamCodeState extends State<ExamCode> {
  final ExamController _examController =
      Get.put<ExamController>(ExamController());
  final FocusNode _examCodeFocusNode = FocusNode();
  String _examCode = "";
  bool _getExamCodeLoading = false;

  @override
  void dispose() {
    _examCodeFocusNode.dispose(); // Pastikan fokus dihapus saat halaman ditutup
    super.dispose();
  }

  Future<void> _onSubmitExamCode() async {
    try {
      if (_examCode.trim().isEmpty) {
        throw 'Kode ujian harus diisi';
      }

      _examCodeFocusNode.unfocus();

      setState(() {
        _getExamCodeLoading = true;
      });
      String examUrl = await _examController.getExamUrl(token: _examCode);
      Get.off(WebScreen(url: examUrl));
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        message: e.toString(),
        duration: const Duration(milliseconds: 1500),
      ));
    } finally {
      setState(() {
        _getExamCodeLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: _examCodeFocusNode,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: "Masukkan kode ujian",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: Colors.blue.shade100,
                  ),
                  inputFormatters: [UpperCaseTextFormatter()],
                  onChanged: (value) {
                    setState(() {
                      _examCode = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  _getExamCodeLoading ? null : _onSubmitExamCode();
                },
                icon: _getExamCodeLoading
                    ? null
                    : const Icon(Icons.wifi_protected_setup_sharp),
                label: _getExamCodeLoading
                    ? LoadingAnimationWidget.progressiveDots(
                        color: Colors.blue, size: 24)
                    : const Text("Cek"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
