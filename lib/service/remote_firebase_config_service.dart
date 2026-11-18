import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves Firebase configuration at runtime instead of relying on the
/// static `google-services.json` baked into the APK at build time.
///
/// Flow: query a DNS TXT record -> base64-decode it into a URL -> fetch
/// that URL's JSON (the same shape as `google-services.json`) -> build
/// [FirebaseOptions] from it. This lets the Firebase project config be
/// rotated remotely (e.g. after a project migration) without shipping a
/// new app build.
///
/// The last successfully-fetched config is cached locally so the app can
/// still start offline on subsequent launches - only the very first launch
/// on a device strictly requires network connectivity.
class RemoteFirebaseConfigService {
  static const String _dnsTxtHost = 'companion.vivinconsulting.com';
  static const String _cacheKey = 'remote_firebase_config_json';

  static const Duration _networkTimeout = Duration(seconds: 6);

  /// Resolves [FirebaseOptions], trying the live DNS TXT record + remote
  /// JSON first, falling back to the last cached config if that fails.
  /// Throws if neither the live fetch nor a cache is available - the
  /// caller must handle that (there's nothing to initialize Firebase with).
  Future<FirebaseOptions> resolveFirebaseOptions() async {
    try {
      final config = await _fetchRemoteConfig();
      if (config != null) {
        await _cacheConfig(config);
        return _optionsFromConfig(config);
      }
    } catch (e) {
      debugPrint('[RemoteFirebaseConfigService] Live fetch failed: $e');
    }

    final cached = await _readCachedConfig();
    if (cached != null) {
      debugPrint('[RemoteFirebaseConfigService] Using cached config.');
      return _optionsFromConfig(cached);
    }

    throw Exception(
      'Could not resolve Firebase configuration: no network and no cached config.',
    );
  }

  /// DNS TXT record -> base64 decode -> URL -> fetch JSON.
  Future<Map<String, dynamic>?> _fetchRemoteConfig() async {
    final configUrl = await _resolveConfigUrlFromDns();
    if (configUrl == null) return null;

    final response = await http
        .get(Uri.parse(configUrl))
        .timeout(_networkTimeout);
    if (response.statusCode != 200) {
      debugPrint(
        '[RemoteFirebaseConfigService] Config fetch HTTP ${response.statusCode}',
      );
      return null;
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Queries the DNS TXT record via Google's public DNS-over-HTTPS
  /// resolver (a plain HTTPS GET - Dart has no built-in TXT record
  /// lookup), then base64-decodes its content into a URL.
  Future<String?> _resolveConfigUrlFromDns() async {
    final uri = Uri.https('dns.google', '/resolve', {
      'name': _dnsTxtHost,
      'type': 'TXT',
    });
    final response = await http.get(uri).timeout(_networkTimeout);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final answers = body['Answer'] as List<dynamic>?;
    if (answers == null || answers.isEmpty) return null;

    // DNS-over-HTTPS returns the TXT value quoted, e.g. "\"aHR0cHM6...\"".
    final rawTxt = answers.first['data'] as String? ?? '';
    final base64Value = rawTxt.replaceAll('"', '').trim();
    if (base64Value.isEmpty) return null;

    return utf8.decode(base64.decode(base64Value));
  }

  Future<void> _cacheConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(config));
  }

  Future<Map<String, dynamic>?> _readCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // The hosted config is a `google-services.json`-shaped file (Android's
  // format), which only ever carries an Android client entry - iOS has no
  // equivalent entry to select there. Project-level fields (project ID,
  // storage bucket, sender ID) are shared across platforms in the same
  // Firebase project, so those still come from the remote config; only
  // the iOS app's own apiKey/appId (from its Firebase-console
  // registration, bundle id com.companion.vivin) are fixed locally.
  static const String _iosApiKey = 'AIzaSyA-BrsxcdfI0wfH9NAV4L5Gg-Fz1wP4LTs';
  static const String _iosAppId = '1:868751188751:ios:ed26f4a96a46397bc2d47a';

  /// Builds [FirebaseOptions] from a `google-services.json`-shaped map.
  FirebaseOptions _optionsFromConfig(Map<String, dynamic> config) {
    final projectInfo = config['project_info'] as Map<String, dynamic>;

    String apiKey;
    String appId;
    if (Platform.isIOS) {
      apiKey = _iosApiKey;
      appId = _iosAppId;
    } else {
      final client = (config['client'] as List<dynamic>).first
          as Map<String, dynamic>;
      final clientInfo = client['client_info'] as Map<String, dynamic>;
      final apiKeys = client['api_key'] as List<dynamic>;
      apiKey = (apiKeys.first as Map<String, dynamic>)['current_key'] as String;
      appId = clientInfo['mobilesdk_app_id'] as String;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: projectInfo['project_number'] as String,
      projectId: projectInfo['project_id'] as String,
      storageBucket: projectInfo['storage_bucket'] as String?,
    );
  }
}













