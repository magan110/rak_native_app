import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

/// Authentication remote data source
/// Data layer - handles API calls
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  
  AuthRemoteDataSourceImpl(this.apiClient);
  
  @override
  Future<UserModel> login(String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
      },
    );
    
    return UserModel.fromJson(response['data']);
  }
  
  @override
  Future<UserModel> register(String email, String password, String name) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      body: {
        'email': email,
        'password': password,
        'name': name,
      },
    );
    
    return UserModel.fromJson(response['data']);
  }
  
  @override
  Future<void> logout() async {
    await apiClient.post(ApiEndpoints.logout);
  }
}
