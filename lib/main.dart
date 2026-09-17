import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constant/app_colors.dart';
import 'constant/app_strings.dart';
import 'model/tenant_model.dart';
import 'screens/login_screen.dart';
import 'screens/tenant_selector_screen.dart';
import 'screens/web_dashboard_screen.dart';
import 'service/auth_service.dart';
import 'service/fcm_service.dart';
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

  // Initialize Firebase & FCM Cloud Messaging
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    await FcmService().initialize();
  } catch (e) {
    debugPrint('Firebase/FCM initialization note: $e');
  }

  // Restore an existing Firebase session, if any, so a signed-in user
  // is taken straight to the tenant dashboard (or picker) instead of the
  // login screen.
  List<TenantMaster> restoredTenants = [];
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
          restoredTenants = tenants;
        } else {
          await AuthService().logout();
        }
      }
    } catch (e) {
      debugPrint('Session restore note: $e');
    }
  }

  // Activate screenshot and screen-recording protection across the entire app
  try {
    await SecurityService().enableScreenshotProtection();
  } catch (e) {
    debugPrint('Security initialization note: $e');
  }

  runApp(CompanionApp(restoredTenants: restoredTenants));
}

class CompanionApp extends StatelessWidget {
  final List<TenantMaster> restoredTenants;

  const CompanionApp({super.key, this.restoredTenants = const []});

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
      home: restoredTenants.isEmpty
          ? const LoginScreen()
          : restoredTenants.length == 1
              ? WebDashboardScreen(
                  tenantUrl: restoredTenants.first.tenantUrl,
                  tenantName: restoredTenants.first.tenantName,
                )
              : TenantSelectorScreen(tenants: restoredTenants),
    );
  }
}






