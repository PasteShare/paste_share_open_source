import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
    ..connectionTimeout = Duration(seconds: 3)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // todo
        return cert.sha1.toString() == "";
      };
  }
}

class ApiClient {
  static ApiClient? _instance;
  static late Client _inner;

  factory ApiClient() {
    if (_instance == null) {
      _inner = Client();
      _instance = ApiClient();
    }
    return _instance!;
  }

  Future<Map<String, dynamic>?> request(String path, {String method = "GET", body}) async {
    Uri uri = Uri.https("lan.liuxuanping.com", path);
    late Response response;
    switch (method) {
      case "GET":
        response = await _inner.get(uri);
        break;
      case "POST":
        response = await _inner.post(uri);
        break;
    }
    final jsonBody = jsonDecode(response.body).cast<String, dynamic>();
    return jsonBody;
  }
}

class LocalApiClient extends BaseClient {
  static LocalApiClient? _instance;
  static late Client _inner;

  factory LocalApiClient() {
    if (_instance == null) {
      _instance = LocalApiClient._internal();
    }
    return _instance!;
  }

  LocalApiClient._internal() {
    _inner = Client();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    return _inner.send(request);
  }
}
