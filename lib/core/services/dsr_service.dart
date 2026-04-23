import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rak_app/core/constants/app_constants.dart';
import 'package:rak_app/core/models/dsr_models.dart';
import 'package:rak_app/core/network/ssl_http_client.dart';

class SubAreaResult {
  final bool hasSubArea;
  final List<DsrOptionItem> data;

  SubAreaResult({required this.hasSubArea, required this.data});
}

class DsrService {
  static String get _baseUrl => AppConstants.baseUrl;
  static const Duration _timeout = Duration(seconds: 45);
  static http.Client? _client;

  static Future<http.Client> _getClient() async {
    _client ??= await SslHttpClient.getClient();
    return _client!;
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const List<DsrOptionItem> _fallbackProducts = [
    DsrOptionItem(code: 'WP', name: 'Birla White Wall Care Putty'),
    DsrOptionItem(code: 'TA', name: 'Tile Adhesive'),
  ];

  static const Map<String, List<DsrSkuItem>> _fallbackSkus = {
    'WP': [
      DsrSkuItem(
        code: '5 KG',
        name: '5 KG',
        catgPack: '5 KG',
        packSize: 5,
        bagsPerTon: 200,
      ),
      DsrSkuItem(
        code: '20 KG',
        name: '20 KG',
        catgPack: '20 KG',
        packSize: 20,
        bagsPerTon: 50,
      ),
    ],
    'TA': [
      DsrSkuItem(
        code: '20 KG',
        name: '20 KG',
        catgPack: '20 KG',
        packSize: 20,
        bagsPerTon: 50,
      ),
    ],
  };

  static String _normalizeValue(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static List<DsrOptionItem> _mergeFallbackProducts(
    List<DsrOptionItem> products,
  ) {
    if (products.isEmpty) {
      return List<DsrOptionItem>.from(_fallbackProducts);
    }

    final merged = List<DsrOptionItem>.from(products);
    final existingNames = products
        .map((item) => _normalizeValue(item.name))
        .where((item) => item.isNotEmpty)
        .toSet();

    for (final fallback in _fallbackProducts) {
      if (!existingNames.contains(_normalizeValue(fallback.name))) {
        merged.add(fallback);
      }
    }

    return merged;
  }

  static List<DsrSkuItem> _fallbackSkusFor(String repoCatg) {
    final normalized = _normalizeValue(repoCatg);
    for (final entry in _fallbackSkus.entries) {
      if (_normalizeValue(entry.key) == normalized) {
        return List<DsrSkuItem>.from(entry.value);
      }
    }
    return const [];
  }

  static Future<List<DsrOptionItem>> getActivities(String deptCode) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/activities?deptCode=${Uri.encodeComponent(deptCode)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  // New: emirates / areas / subareas helpers matching the server controller
  static Future<List<DsrOptionItem>> getEmiratesList() async {
    final client = await _getClient();
    final uri = Uri.parse('$_baseUrl/api/Dsr/emirates');
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<DsrOptionItem>> getAreasList(String emirateCode) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/areas?emirateCode=${Uri.encodeComponent(emirateCode)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Returns raw area objects (to access additional fields like `pobox`).
  static Future<List<Map<String, dynamic>>> getAreasListRaw(
    String emirateCode,
  ) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/areas?emirateCode=${Uri.encodeComponent(emirateCode)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      final raw = (body['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      // Normalize keys to consistent lowercase names for UI consumption
      return raw.map((m) => _normalizeAreaMap(m)).toList();
    }
    return [];
  }

  static Future<SubAreaResult> getSubAreasList(String areaCode) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/subareas?areaCode=${Uri.encodeComponent(areaCode)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      final has =
          (body['hasSubArea'] == true) ||
          (body['data'] is List && (body['data'] as List).isNotEmpty);
      final List<DsrOptionItem> list = [];
      if (body['data'] is List) {
        list.addAll(
          (body['data'] as List).map(
            (e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)),
          ),
        );
      }
      return SubAreaResult(hasSubArea: has, data: list);
    }
    return SubAreaResult(hasSubArea: false, data: []);
  }

  /// Returns raw subarea response preserving `hasSubArea` and raw `data` list.
  static Future<SubAreaResult> getSubAreasListRaw(String areaCode) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/subareas?areaCode=${Uri.encodeComponent(areaCode)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      final has =
          (body['hasSubArea'] == true) ||
          (body['data'] is List && (body['data'] as List).isNotEmpty);
      final List<Map<String, dynamic>> list = [];
      if (body['data'] is List) {
        list.addAll(
          (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
      return SubAreaResult(
        hasSubArea: has,
        data: list
            .map((m) => DsrOptionItem.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
    }
    return SubAreaResult(hasSubArea: false, data: []);
  }

  /// Returns raw subarea map preserving `hasSubArea` and `data` list as maps.
  static Future<Map<String, dynamic>> getSubAreasRaw(String areaCode) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/subareas?areaCode=${Uri.encodeComponent(areaCode)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      final list = <Map<String, dynamic>>[];
      if (body['data'] is List) {
        list.addAll(
          (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
      final normalized = list.map((m) => _normalizeAreaMap(m)).toList();
      return {
        'hasSubArea': (body['hasSubArea'] == true) || normalized.isNotEmpty,
        'data': normalized,
      };
    }
    return {'hasSubArea': false, 'data': <Map<String, dynamic>>[]};
  }

  static Map<String, dynamic> _normalizeAreaMap(Map<String, dynamic> raw) {
    // Extract possible variants and produce consistent lowercase keys used by UI
    final code =
        (raw['code'] ?? raw['Code'] ?? raw['value'] ?? raw['Value'] ?? '')
            .toString();
    final name =
        (raw['name'] ?? raw['Name'] ?? raw['text'] ?? raw['Text'] ?? '')
            .toString();
    final poBox =
        (raw['pobox'] ?? raw['PoBox'] ?? raw['poBox'] ?? raw['PoBox'] ?? '')
            .toString();
    // Keep originals under 'orig' if needed
    return {'code': code, 'name': name, 'pobox': poBox, 'orig': raw};
  }

  static Future<DsrTemplate?> getTemplate({
    required String dsrParam,
    required String deptCode,
  }) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/template?dsrParam=${Uri.encodeComponent(dsrParam)}&deptCode=${Uri.encodeComponent(deptCode)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is Map<String, dynamic>) {
      return DsrTemplate.fromJson(Map<String, dynamic>.from(body['data']));
    }
    return null;
  }

  // Legacy helper kept for backward compatibility (calls server with loginId param)
  static Future<List<DsrOptionItem>> getAreas(String loginId) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/areas?loginId=${Uri.encodeComponent(loginId)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<DsrOptionItem>> getPartyTypes() async {
    final client = await _getClient();
    final uri = Uri.parse('$_baseUrl/api/Dsr/party-types');
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<DsrOptionItem>> getDocumentTypes() async {
    final client = await _getClient();
    final uri = Uri.parse('$_baseUrl/api/Dsr/document-types');
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<DsrOptionItem>> getGiftTypes() async {
    final client = await _getClient();
    final uri = Uri.parse('$_baseUrl/api/Dsr/gift-types');
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<DsrOptionItem>> getProducts({String search = ''}) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/products?search=${Uri.encodeComponent(search)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      final products = (body['data'] as List)
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return _mergeFallbackProducts(products);
    }
    return List<DsrOptionItem>.from(_fallbackProducts);
  }

  static Future<List<DsrSkuItem>> getSkus(String repoCatg) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/skus?repoCatg=${Uri.encodeComponent(repoCatg)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      final skus = (body['data'] as List)
          .map((e) => DsrSkuItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return skus.isEmpty ? _fallbackSkusFor(repoCatg) : skus;
    }
    return _fallbackSkusFor(repoCatg);
  }

  // Updated: include optional subArCod param when searching parties
  static Future<List<DsrParty>> searchParty({
    required String partyType,
    required String areaCode,
    String subArCod = '',
    required String search,
  }) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/party-search?partyType=${Uri.encodeComponent(partyType)}&areaCode=${Uri.encodeComponent(areaCode)}&subArCod=${Uri.encodeComponent(subArCod)}&search=${Uri.encodeComponent(search)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrParty.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<DsrDocumentSummary>> getDocuments({
    required String loginId,
    String dsrParam = '',
  }) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/documents?loginId=${Uri.encodeComponent(loginId)}&dsrParam=${Uri.encodeComponent(dsrParam)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .map((e) => DsrDocumentSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getDetail({
    required String docuNumb,
    required String loginId,
  }) async {
    final client = await _getClient();
    final uri = Uri.parse(
      '$_baseUrl/api/Dsr/detail?docuNumb=${Uri.encodeComponent(docuNumb)}&loginId=${Uri.encodeComponent(loginId)}',
    );
    final response = await client.get(uri).timeout(_timeout);
    final body = jsonDecode(response.body);
    if (body['success'] == true && body['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(body['data']);
    }
    return null;
  }

  static Future<DsrSaveResponse> saveDsr(DsrSaveRequest request) async {
    final client = await _getClient();
    final uri = Uri.parse('$_baseUrl/api/Dsr/save');
    final outgoing = jsonEncode(request.toJson());
    // Temporary debug log: print outgoing request JSON
    try {
      print('DSR SERVICE OUTGOING JSON: $outgoing');
    } catch (_) {}

    final response = await client
        .post(uri, headers: _headers, body: outgoing)
        .timeout(_timeout);

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    return DsrSaveResponse.fromJson(body);
  }

  static String todayDmy() {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    return '$dd/$mm/$yyyy';
  }

  static String nz(String? s) => s?.trim() ?? '';
  static bool isBlank(String? s) => s == null || s.trim().isEmpty;

  static String inferCuRtType(String partyType) {
    switch (partyType) {
      case 'R':
        return 'RT';
      case 'C':
        return 'ST';
      case 'RD':
        return 'RD';
      case 'RR':
        return 'RR';
      case 'D':
        return 'DD';
      case 'AD':
        return 'AD';
      case 'UR':
        return 'UR';
      case '3':
        return '3';
      case '07':
        return '07';
      case '08':
        return '08';
      default:
        return partyType;
    }
  }

  static String resolvePartyTypeForEdit({
    required String cusRtlFl,
    required String cuRtType,
  }) {
    switch (nz(cuRtType)) {
      case 'RT':
        return 'R';
      case 'ST':
        return 'C';
      case 'RD':
        return 'RD';
      case 'RR':
        return 'RR';
      case 'DD':
        return 'D';
      case 'AD':
        return 'AD';
      case 'UR':
        return 'UR';
      case '07':
        return '07';
      case '08':
        return '08';
      case '3':
        return '3';
    }

    switch (nz(cusRtlFl)) {
      case 'R':
      case 'C':
      case 'D':
      case 'AD':
      case 'UR':
      case 'RD':
      case 'RR':
      case '07':
      case '08':
      case '3':
        return nz(cusRtlFl);
      default:
        return nz(cuRtType).isNotEmpty ? nz(cuRtType) : nz(cusRtlFl);
    }
  }
}
