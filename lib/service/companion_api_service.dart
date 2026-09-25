import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constant/app_config.dart';
import '../model/companion_session_model.dart';

/// Talks to the companionAPI backend directly (as opposed to the web
/// dashboard, which the app only ever drives through a WebView).
class CompanionApiService {
  static const _timeout = Duration(seconds: 20);

  /// Exchanges an already-verified Firebase ID token for a web dashboard
  /// session, via the backend's `LoginWithFirebase` endpoint. That endpoint
  /// re-verifies the token server-side and issues the same kind of JWT a
  /// normal username/password login would.
  Future<CompanionSession> loginWithFirebase(String idToken) async {
    final uri = Uri.parse('${AppConfig.companionApiBaseUrl}/Login/LoginWithFirebase');

    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'LoginWithFirebase failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw Exception('LoginWithFirebase returned no session.');
    }

    return CompanionSession.fromJson(decoded.first as Map<String, dynamic>);
  }

  /// Step 2a of the phone-number-first login flow: asks the backend to
  /// generate and send an OTP for this mobile number. The code itself
  /// never comes back to the client - only whether the request succeeded.
  Future<void> requestOtp(String mobileNo) async {
    final uri = Uri.parse('${AppConfig.companionApiBaseUrl}/Login/RequestOtp');

    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'mobileNo': mobileNo}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('RequestOtp failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Step 2a completion: verifies the OTP server-side and, on success,
  /// returns a Firebase custom token the app signs in with - the account's
  /// real password is never involved or exposed.
  Future<String> verifyOtpAndLogin(String mobileNo, String code) async {
    final uri = Uri.parse('${AppConfig.companionApiBaseUrl}/Login/VerifyOtpAndLogin');

    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'mobileNo': mobileNo, 'code': code}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('VerifyOtpAndLogin failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final customToken = decoded['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw Exception('VerifyOtpAndLogin returned no token.');
    }
    return customToken;
  }
}
