import 'api_base_helper.dart';
import 'api_constants.dart';

class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.username,
    this.userId,
    this.email,
    this.mobile,
  });

  final bool success;
  final String message;
  final String? token;
  // Only populated by login() — register()/socialSignUp() already know the
  // name/email/mobile the user just typed/picked, so callers use those
  // directly instead when this comes back null.
  final String? username;
  final String? userId;
  final String? email;
  final String? mobile;
}

class ProfileUpdateResult {
  const ProfileUpdateResult({
    required this.success,
    required this.message,
    this.username,
    this.email,
    this.mobile,
  });

  final bool success;
  final String message;
  final String? username;
  final String? email;
  final String? mobile;
}

class AuthService {
  AuthService(this._api);

  final ApiBaseHelper _api;

  Future<AuthResult> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _api.post(getUserLoginApi, {
      'mobile': mobile,
      'password': password,
    });
    return _resultFrom(response);
  }

  /// Login-or-register with a Google identity token. The backend verifies
  /// the token and derives identity/profile details from Google's payload.
  Future<AuthResult> socialSignUp({required String idToken}) async {
    final response = await _api.post(signUpUserApi, {'id_token': idToken});
    return _resultFrom(response);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final response = await _api.post(getUserSignUpApi, {
      'name': name,
      'email': email,
      'mobile': mobile,
      'password': password,
    });
    return _resultFrom(response);
  }

  /// update_user identifies the account from the Bearer token and only
  /// touches fields that are actually present. Its response
  /// `data` is a single user object (unlike login/register's one-item
  /// list), so this has its own parsing rather than sharing _resultFrom.
  Future<ProfileUpdateResult> updateProfile({
    String? username,
    String? email,
    String? mobile,
  }) async {
    final response = await _api.post(updateUserApi, {
      if (username != null && username.isNotEmpty) 'username': username,
      if (email != null && email.isNotEmpty) 'email': email,
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
    });
    if (response is! Map) {
      return const ProfileUpdateResult(
        success: false,
        message: 'Unexpected server response',
      );
    }
    final error = response['error'] == true;
    final data = response['data'];
    return ProfileUpdateResult(
      success: !error,
      message: '${response['message'] ?? ''}',
      username: data is Map && '${data['username'] ?? ''}'.isNotEmpty
          ? '${data['username']}'
          : null,
      email: data is Map && '${data['email'] ?? ''}'.isNotEmpty
          ? '${data['email']}'
          : null,
      mobile: data is Map && '${data['mobile'] ?? ''}'.isNotEmpty
          ? '${data['mobile']}'
          : null,
    );
  }

  AuthResult _resultFrom(dynamic response) {
    if (response is! Map) {
      return const AuthResult(
        success: false,
        message: 'Unexpected server response',
      );
    }
    final error = response['error'] == true;
    final message = '${response['message'] ?? ''}';
    final token = response['token'] == null ? null : '${response['token']}';
    // login/register/sign_up all return `data` as a one-item list with the
    // user's row (see Api.php's login()) — username lives at data[0].
    final data = response['data'];
    final row = data is List && data.isNotEmpty ? data.first : null;
    String? field(String key) =>
        row is Map && '${row[key] ?? ''}'.isNotEmpty ? '${row[key]}' : null;
    return AuthResult(
      success: !error,
      message: message,
      token: token,
      username: field('username'),
      userId: field('id'),
      email: field('email'),
      mobile: field('mobile'),
    );
  }
}
