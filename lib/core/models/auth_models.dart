// TODO Implement this library.
class LoginRequest {
  final String userID;
  final String password;
  final String appRegId;

  const LoginRequest({
    required this.userID,
    required this.password,
    required this.appRegId,
  });

  Map<String, dynamic> toJson() => {
    'userID': userID,
    'password': password,
    'appRegId': appRegId,
  };

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
    userID: json['userID'] as String,
    password: json['password'] as String,
    appRegId: json['appRegId'] as String,
  );
}

class LoginResponse {
  final String msg;
  final UserData data;

  const LoginResponse({required this.msg, required this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    msg: json['msg'] as String,
    data: UserData.fromJson(json['data'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'msg': msg, 'data': data.toJson()};
}

class AutoLoginRequest {
  final String appRegId;

  const AutoLoginRequest({required this.appRegId});

  Map<String, dynamic> toJson() => {'appRegId': appRegId};

  factory AutoLoginRequest.fromJson(Map<String, dynamic> json) =>
      AutoLoginRequest(appRegId: json['appRegId'] as String);
}

class LogoutRequest {
  final String appRegId;

  const LogoutRequest({required this.appRegId});

  Map<String, dynamic> toJson() => {'appRegId': appRegId};

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      LogoutRequest(appRegId: json['appRegId'] as String);
}

class UserData {
  final String emplName;
  final String areaCode;
  final List<String> roles;
  final List<String> pages;
  final String? userID; // Add userID field
  final String? appRegId; // Add appRegId field

  const UserData({
    required this.emplName,
    required this.areaCode,
    required this.roles,
    required this.pages,
    this.userID,
    this.appRegId,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    emplName: json['emplName'] as String,
    areaCode: json['areaCode'] as String,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
    pages: (json['pages'] as List<dynamic>).cast<String>(),
    userID: json['userID'] as String?,
    appRegId: json['appRegId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'emplName': emplName,
    'areaCode': areaCode,
    'roles': roles,
    'pages': pages,
    'userID': userID,
    'appRegId': appRegId,
  };

  bool hasRole(String role) => roles.contains(role);
  bool hasPage(String page) => pages.contains(page);
  bool hasAnyRole(List<String> roleList) =>
      roleList.any((role) => roles.contains(role));
  bool hasAnyPage(List<String> pageList) =>
      pageList.any((page) => pages.contains(page));
}
