import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  static const String defaultBaseUrl = 'https://tornadefter.onrender.com/api/v1';
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _baseUrl = defaultBaseUrl;

  String get baseUrl => _baseUrl;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _initUrl();

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final companyId = await _storage.read(key: 'active_company_id');
        if (companyId != null) {
          options.headers['X-Company-Id'] = companyId;
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token yenileme dene
          try {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              final response = await Dio().post(
                '$baseUrl/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newToken = response.data['access_token'];
              final newRefresh = response.data['refresh_token'];
              await _storage.write(key: 'access_token', value: newToken);
              await _storage.write(key: 'refresh_token', value: newRefresh);

              // Orijinal isteği yeniden gönder
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (_) {
            // Refresh başarısız, login'e yönlendir
            await _storage.deleteAll();
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> _initUrl() async {
    try {
      final savedUrl = await _storage.read(key: 'custom_api_base_url');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrl = savedUrl.trim();
        dio.options.baseUrl = _baseUrl;
      }
    } catch (_) {}
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    dio.options.baseUrl = _baseUrl;
    await _storage.write(key: 'custom_api_base_url', value: _baseUrl);
  }

  Future<String> getBaseUrl() async {
    try {
      final savedUrl = await _storage.read(key: 'custom_api_base_url');
      return savedUrl?.trim() ?? _baseUrl;
    } catch (_) {
      return _baseUrl;
    }
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> setActiveCompany(String companyId) async {
    await _storage.write(key: 'active_company_id', value: companyId);
  }

  Future<String?> getActiveCompany() async {
    return _storage.read(key: 'active_company_id');
  }

  Future<String?> ensureActiveCompany() async {
    var companyId = await getActiveCompany();
    if (companyId != null && companyId.isNotEmpty) return companyId;
    try {
      final res = await dio.get('/companies');
      final list = res.data is List ? res.data : (res.data?['data'] ?? []);
      if (list is List && list.isNotEmpty) {
        companyId = list[0]['id'];
        await setActiveCompany(companyId!);
        return companyId;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters);
  }
}

