import 'commercial_licence_ocr_service.dart';

void main() async {
  // TODO: Replace with your actual API endpoint and file path
  const apiUrl =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTYzNDEyMDQzMiwianRpIjoiMjY2YzliZGQtNTYyOC00M2I1LThkOGQtZjc5NjNjNGFjMmZkIiwidHlwZSI6ImFjY2VzcyIsImlkZW50aXR5IjoiZGV2LmFkaXR5YWJpcmxhQGFhZGhhYXJhcGkuaW8iLCJuYmYiOjE2MzQxMjA0MzIsImV4cCI6MTk0OTQ4MDQzMiwidXNlcl9jbGFpbXMiOnsic2NvcGVzIjpbInJlYWQiXX19._tHfR3FwZsQZ-EBvKlga031KdCPeUdXGw-JksGRIQVE';
  const filePath =
      'C:\\Users\\magan\\Downloads\\1. KDU LLC TRADE LICENSE S27.12.2025_compressed-1.pdf';

  final result = await CommercialLicenseOcrService.processDocument(
    apiUrl,
    filePath,
  );

  if (result != null) {
    print('API key is working. OCR result received.');
  } else {
    print('API key may be invalid or there was an error.');
  }
}
