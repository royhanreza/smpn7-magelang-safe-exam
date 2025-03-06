import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:safe_exam/src/service/api.dart';
import 'package:safe_exam/utils/service.dart';

class ExamController extends GetxController {
  final Dio _dio = Dio();
  final Api _api = Api();

  Future<String> getExamUrl({required String token}) async {
    try {
      final response =
          await _dio.get('${_api.baseUrl}/api/v1/exam-token?token=$token');

      final Map responseJson = response.data['data'];

      print(responseJson);

      if (responseJson.containsKey('link')) {
        return responseJson['link'];
      }

      throw DioException(
          requestOptions: RequestOptions(), message: 'Link tidak tersedia');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
