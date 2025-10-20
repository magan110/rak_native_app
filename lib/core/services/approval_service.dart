import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/approval_models.dart';

class ApprovalService {
  static const String baseUrl = 'https://qa.birlawhite.com:55232';

  Future<ApprovalResponse> getPendingApprovals({
    String? search,
    String? type,
    int page = 1,
    int pageSize = 20,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final uri = Uri.parse(
        '$baseUrl/api/Approval/pending',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load pending approvals: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching pending approvals: $e');
    }
  }

  Future<ApprovalStats> getApprovalStats() async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/stats');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalStats.fromJson(data);
      } else {
        throw Exception(
          'Failed to load approval stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching approval stats: $e');
    }
  }

  Future<ApprovalActionResponse> approveItem(
    String inflCode, {
    String? actorId,
  }) async {
    try {
      final request = ApprovalActionRequest(
        inflCode: inflCode,
        actorId: actorId,
      );

      final uri = Uri.parse('$baseUrl/api/Approval/approve');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to approve item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving item: $e');
    }
  }

  Future<ApprovalActionResponse> rejectItem(
    String inflCode, {
    String? reason,
    String? actorId,
  }) async {
    try {
      final request = RejectionActionRequest(
        inflCode: inflCode,
        reason: reason,
        actorId: actorId,
      );

      final uri = Uri.parse('$baseUrl/api/Approval/reject');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to reject item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting item: $e');
    }
  }

  Future<String> lookupInflCode(String identifier) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/lookup/$identifier');
      print('DEBUG API: Looking up inflCode for identifier: $identifier');
      print('DEBUG API: Lookup URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('DEBUG API: Lookup response status: ${response.statusCode}');
      print('DEBUG API: Lookup response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final inflCode = data['inflCode'] ?? '';
        print('DEBUG API: Found inflCode: $inflCode');
        return inflCode;
      } else if (response.statusCode == 404) {
        throw Exception('Person not found for identifier: $identifier');
      } else {
        throw Exception(
          'Failed to lookup inflCode: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG API: Lookup exception: $e');
      throw Exception('Error looking up inflCode: $e');
    }
  }

  Future<RegistrationDetails> getRegistrationDetails(String inflCode) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/details/$inflCode');
      print('DEBUG API: Requesting URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG API: Parsed data: $data');
        return RegistrationDetails.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception(
          'Registration details not found for inflCode: $inflCode',
        );
      } else {
        throw Exception(
          'Failed to load registration details: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG API: Exception occurred: $e');
      throw Exception('Error fetching registration details: $e');
    }
  }

  Future<RegistrationDetails> getRegistrationDetailsByIdentifier(
    String identifier,
  ) async {
    try {
      print('DEBUG: Getting details for identifier: $identifier');

      // First lookup the inflCode
      final inflCode = await lookupInflCode(identifier);

      // Then get the full details
      return await getRegistrationDetails(inflCode);
    } catch (e) {
      print('DEBUG: Error in getRegistrationDetailsByIdentifier: $e');
      rethrow;
    }
  }
}
