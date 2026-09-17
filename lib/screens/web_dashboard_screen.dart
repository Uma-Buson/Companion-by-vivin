import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../service/auth_service.dart';
import 'login_screen.dart';

/// Post-login destination: loads the tenant's web app (`companionapp`)
/// inside a WebView, per the tenant's `tenantUrl` from `tenantMaster`.
class WebDashboardScreen extends StatefulWidget {
  final String tenantUrl;
  final String tenantName;

  const WebDashboardScreen({
    super.key,
    required this.tenantUrl,
    required this.tenantName,
  });

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.scaffoldBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _loadError = null;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) => setState(() {
            _isLoading = false;
            _loadError = error.description;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.tenantUrl));
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              AppStrings.logoutButton,
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<bool> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (!shouldPop || !context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tenantName),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: AppStrings.logoutButton,
              onPressed: _confirmLogout,
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_loadError == null) WebViewWidget(controller: _controller),
            if (_loadError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load the dashboard.\n$_loadError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          _controller.reload();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading && _loadError == null)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
          ],
        ),
      ),
    );
  }
}
