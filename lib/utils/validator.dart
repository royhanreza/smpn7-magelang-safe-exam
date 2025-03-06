class Validator {
  // Fungsi untuk memvalidasi URL
  static bool isValidUrl(String url) {
    RegExp polaUrl = RegExp(
      r'^(https?|ftp)://' // Harus diawali dengan http, https, atau ftp
      r'([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,6})' // Domain utama (contoh: example.com)
      r'(:\d+)?' // Port opsional (contoh: :8080)
      r'(/[\w.-]*)*$', // Path opsional (contoh: /path/to/page)
      caseSensitive: false,
    );

    return polaUrl.hasMatch(url);
  }
}
