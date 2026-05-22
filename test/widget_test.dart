import 'package:flutter_test/flutter_test.dart';
import 'package:tekeraheza_mobile/core/api/api_constants.dart';

void main() {
  test('API base URL points to AWS backend', () {
    expect(ApiConstants.baseUrl, contains('api.tekeraheza.systems'));
    expect(ApiConstants.baseUrl, endsWith('/api'));
  });
}
