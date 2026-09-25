import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constant/app_colors.dart';
import 'constant/app_strings.dart';
import 'model/companion_session_model.dart';
import 'model/tenant_model.dart';
import 'screens/login_screen.dart';
import 'screens/web_dashboard_screen.dart';
import 'service/auth_service.dart';
import 'service/companion_api_service.dart';
import 'service/fcm_service.dart';
import 'service/remote_firebase_config_service.dart';
import 'service/security_service.dart';
import 'service/tenant_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Resolve Firebase config remotely (DNS TXT record -> URL -> JSON) rather
  // than the static google-services.json baked into the build, so the
  // Firebase project can be rotated without a new app release. Falls back
  // to the last cached config if offline; only fails on a brand-new
  // install with no network at all.
  bool firebaseReady = false;
  String? firebaseConfigError;
  try {
    final options = await RemoteFirebaseConfigService().resolveFirebaseOptions();
    await Firebase.initializeApp(options: options);
    firebaseReady = true;
    await FcmService().initialize();
  } catch (e) {
    firebaseConfigError = e.toString();
    debugPrint('Firebase/FCM initialization note: $e');
  }

  // Restore an existing Firebase session, if any, so a signed-in user
  // is taken straight to the tenant dashboard (or picker) instead of the
  // login screen.
  List<TenantMaster> restoredTenants = [];
  CompanionSession? restoredSession;
  if (firebaseReady) {
    try {
      final restoredUser = await AuthService().tryRestoreSession();
      if (restoredUser != null) {
        // Re-check tenant access on every restart, not just at login time,
        // so a tenant deactivated since the last session doesn't leave a
        // stale session usable.
        final tenants = await TenantService().getActiveTenantsForUser(
          restoredUser.id,
        );
        if (tenants.isNotEmpty) {
          // Also re-establish the web dashboard session, since the
          // WebView needs a fresh one to inject on this launch - the
          // previous one only lived in that now-gone WebView's localStorage.
          // No upfront signal for which company this user belongs to, so
          // try each known companionAPI backend in turn, same as at login.
          final knownApiBaseUrls = await TenantService().getKnownApiBaseUrls();
          final session = await CompanionApiService().loginWithFirebaseTryingBackends(
            knownApiBaseUrls,
            restoredUser.token,
          );
          restoredTenants = tenants;
          restoredSession = session;
        } else {
          await AuthService().logout();
        }
      }
    } catch (e) {
      debugPrint('Session restore note: $e');
      restoredTenants = [];
      restoredSession = null;
      await AuthService().logout();
    }
  }

  // Activate screenshot and screen-recording protection across the entire app
  try {
    await SecurityService().enableScreenshotProtection();
  } catch (e) {
    debugPrint('Security initialization note: $e');
  }

  runApp(
    CompanionApp(
      restoredTenants: restoredTenants,
      restoredSession: restoredSession,
      firebaseConfigError: firebaseReady ? null : firebaseConfigError,
    ),
  );
}

class CompanionApp extends StatelessWidget {
  final List<TenantMaster> restoredTenants;
  final CompanionSession? restoredSession;
  final String? firebaseConfigError;

  const CompanionApp({
    super.key,
    this.restoredTenants = const [],
    this.restoredSession,
    this.firebaseConfigError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryRed,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.primaryRedLight,
          onSecondary: Colors.white,
          surface: AppColors.surfaceWhite,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 1.5,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryRed,
            side: const BorderSide(color: AppColors.primaryRed),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.scaffoldBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
        ),
      ),
      home: firebaseConfigError != null
          ? _ConfigUnavailableScreen(error: firebaseConfigError!)
          : (restoredTenants.isEmpty || restoredSession == null)
              ? const LoginScreen()
              : WebDashboardScreen(
                  tenants: restoredTenants,
                  session: restoredSession!,
                ),
    );
  }
}

/// Shown only when Firebase config couldn't be resolved at all - no live
/// DNS/network fetch succeeded AND no cached config exists locally. This
/// should only realistically happen on a brand-new install with no
/// network connectivity at first launch.
class _ConfigUnavailableScreen extends StatelessWidget {
  final String error;

  const _ConfigUnavailableScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not connect',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This device needs an internet connection the first time '
                  'the app starts. Please check your connection and try '
                  'again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


























