import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/storage_service.dart';
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
    // Use appRegId from storage or generate a new one
    var appRegId = await StorageService.getAppRegId();
    appRegId ??= StorageService.generateAppRegId();

    final response = await apiClient.post(
      ApiEndpoints.authLogin,
      body: {
        'userID': email,
        'password': password,
        'appRegId': appRegId,
      },
    );

    // Save appRegId if login succeeded
    if (response != null && response['success'] == true && response['data'] != null) {
      await StorageService.saveAppRegId(appRegId);
    }

    // Map response to existing UserModel if possible, otherwise throw
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid login response');
    }

    // The backend returns emplName/areaCode/roles/pages - create a minimal user model
    // Fallback to existing UserModel structure if keys present
    if (data.containsKey('userID') || data.containsKey('emplName')) {
      // Create a UserModel-like object only if compatible fields exist
      // Here we map emplName -> name and userID -> id/email for compatibility
      return UserModel(
        id: data['userID']?.toString() ?? data['id']?.toString() ?? email,
        email: data['userID']?.toString() ?? email,
        name: data['emplName']?.toString() ?? data['name']?.toString() ?? email,
        profileImage: null,
      );
    }

    // Otherwise try to use existing mapping
    return UserModel.fromJson(data);
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
