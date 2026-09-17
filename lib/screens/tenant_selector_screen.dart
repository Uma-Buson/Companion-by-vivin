import 'package:flutter/material.dart';

import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../constant/app_text_styles.dart';
import '../model/tenant_model.dart';
import '../service/auth_service.dart';
import 'login_screen.dart';
import 'web_dashboard_screen.dart';

/// Shown after login when the signed-in user has Active access to more
/// than one tenant — lets them pick which one to open.
class TenantSelectorScreen extends StatelessWidget {
  final List<TenantMaster> tenants;

  const TenantSelectorScreen({super.key, required this.tenants});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openTenant(BuildContext context, TenantMaster tenant) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WebDashboardScreen(
          tenantUrl: tenant.tenantUrl,
          tenantName: tenant.tenantName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Select Company'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: AppStrings.logoutButton,
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: tenants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tenant = tenants[index];
            return Material(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              elevation: 1.5,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openTenant(context, tenant),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.redSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          tenant.tenantName,
                          style: AppTextStyles.heading2,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
