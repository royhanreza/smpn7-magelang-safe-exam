import 'package:dio/dio.dart';

String handleDioError(DioException e) {
  if (e.response?.data is Map<String, dynamic>) {
    return e.response?.data["message"] ??
        "Terjadi kesalahan, silakan coba lagi.";
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return "Koneksi timeout, periksa jaringan Anda.";
    case DioExceptionType.sendTimeout:
      return "Gagal mengirim data, coba lagi.";
    case DioExceptionType.receiveTimeout:
      return "Waktu respons habis, coba lagi.";
    case DioExceptionType.badResponse:
      return "Terjadi kesalahan server: ${e.response?.statusCode}";
    case DioExceptionType.cancel:
      return "Permintaan dibatalkan.";
    case DioExceptionType.connectionError:
      return "Tidak dapat terhubung ke server, periksa koneksi internet Anda.";
    default:
      return "Terjadi kesalahan: ${e.message ?? 'Tidak diketahui'}";
  }
}
