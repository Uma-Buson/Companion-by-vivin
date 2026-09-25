import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../constant/app_text_styles.dart';
import '../model/companion_session_model.dart';
import '../model/tenant_model.dart';
import '../service/auth_service.dart';
import '../service/location_service.dart';
import 'login_screen.dart';

/// Post-login destination. If the user has one tenant, this just shows its
/// WebView full-screen. If they have several, the app bar shows a tab per
/// tenant and the WebView below it swaps to match the selected tab — each
/// tenant keeps its own WebViewController so switching tabs doesn't reload.
class WebDashboardScreen extends StatefulWidget {
  final List<TenantMaster> tenants;

  /// The already-authenticated web dashboard session (from
  /// LoginWithFirebase) injected into each tenant's WebView so it opens
  /// straight to the dashboard instead of its own login page.
  final CompanionSession session;

  const WebDashboardScreen({
    super.key,
    required this.tenants,
    required this.session,
  });

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _geofenceCheckInterval = Duration(seconds: 30);

  late final TabController _tabController;
  // Lazy per-tenant: a tenant's WebView is only created (and starts
  // loading) the first time its tab is actually selected, rather than all
  // tenants loading in parallel at once - fewer simultaneous connections
  // on a flaky LAN means fewer timeouts.
  late final List<_TenantWebViewHolder?> _holders;

  final LocationService _locationService = LocationService();
  Timer? _geofenceTimer;
  bool _isOutOfBoundary = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tenants.length, vsync: this);
    _holders = List<_TenantWebViewHolder?>.filled(widget.tenants.length, null);
    _ensureHolder(0);
    // Without this, tapping a tab moves the TabController's index but never
    // triggers a rebuild of this widget, so the IndexedStack below keeps
    // showing whatever tab was selected at the last build.
    _tabController.addListener(() {
      if (!mounted) return;
      _ensureHolder(_tabController.index);
      setState(() {});
    });

    _startGeofenceMonitorIfNeeded();
  }

  /// Continuously checks the device's location against the session's
  /// boundary (if one is configured) while the dashboard is open: within
  /// range, the app works normally; outside it, the screen blurs with a
  /// warning and only a logout button - checked immediately on arrival,
  /// then on a timer, since the user's position can change while the app
  /// stays open.
  void _startGeofenceMonitorIfNeeded() {
    final session = widget.session;
    if (!session.latlongActive ||
        session.latitude == null ||
        session.longitude == null ||
        session.geoDistanceMeters == null) {
      return;
    }

    _checkGeofence();
    _geofenceTimer = Timer.periodic(_geofenceCheckInterval, (_) => _checkGeofence());
  }

  Future<void> _checkGeofence() async {
    final session = widget.session;
    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;

    // Can't confirm the device is within a boundary meant to confirm
    // exactly that - treat an unreadable location as out of bounds rather
    // than silently letting it through.
    if (!location.hasCoordinates) {
      setState(() => _isOutOfBoundary = true);
      return;
    }

    final distance = Geolocator.distanceBetween(
      location.latitude!,
      location.longitude!,
      session.latitude!,
      session.longitude!,
    );
    setState(() => _isOutOfBoundary = distance > session.geoDistanceMeters!);
  }

  void _ensureHolder(int index) {
    _holders[index] ??= _TenantWebViewHolder(
      widget.tenants[index],
      widget.session,
      onLoggedOut: _handleWebLogout,
    );
  }

  // The web dashboard's own logout button clears its localStorage and
  // navigates itself to /auth/login - it has no way to reach back into the
  // native app, so this is what actually ends the session on this side:
  // signs out of Firebase (otherwise the next app launch's session-restore
  // would just log the user straight back in) and returns to the native
  // login screen.
  bool _loggedOutHandled = false;

  Future<void> _handleWebLogout() async {
    if (_loggedOutHandled || !mounted) return;
    _loggedOutHandled = true;

    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _geofenceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _handleBackNavigation() async {
    final current = _holders[_tabController.index]?.controller;
    if (current == null) return true;
    if (await current.canGoBack()) {
      await current.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final showTabs = widget.tenants.length > 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (!shouldPop || !context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  if (showTabs)
                    _TenantTabBar(
                      tenants: widget.tenants,
                      selectedIndex: _tabController.index,
                      onSelected: (i) => _tabController.animateTo(i),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: showTabs ? _tabController.index : 0,
                      children: [
                        for (final holder in _holders)
                          if (holder != null)
                            _TenantWebView(holder: holder)
                          else
                            const ColoredBox(color: AppColors.scaffoldBackground),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isOutOfBoundary)
                _OutOfBoundaryOverlay(onLogout: _handleWebLogout),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen blurred scrim shown whenever the geofence monitor finds the
/// device outside its allowed boundary. The dashboard underneath keeps
/// running (so it resumes instantly once back in range), but this blocks
/// all interaction with it - logout is the only way out.
class _OutOfBoundaryOverlay extends StatelessWidget {
  final VoidCallback onLogout;

  const _OutOfBoundaryOverlay({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: AppColors.scaffoldBackground.withValues(alpha: 0.6),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    size: 48,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.outOfBoundaryTitle,
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.outOfBoundaryMessage,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        AppStrings.outOfBoundaryLogoutButton,
                        style: AppTextStyles.buttonLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded pill-style tenant switcher — a horizontal row of rounded
/// capsules (selected = solid red fill, unselected = red-outlined white)
/// rather than the default Material underline TabBar.
class _TenantTabBar extends StatelessWidget {
  final List<TenantMaster> tenants;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TenantTabBar({
    required this.tenants,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < tenants.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _TenantPill(
                  label: tenants[i].tenantName,
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TenantPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TenantPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryRed : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryRed : AppColors.inputBorder,
              width: selected ? 0 : 1.2,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 16,
                color: selected ? AppColors.textOnPrimary : AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns one tenant's WebViewController and load/error state, independent
/// of which tab is currently visible.
class _TenantWebViewHolder {
  final TenantMaster tenant;
  final CompanionSession session;
  final VoidCallback onLoggedOut;
  late final WebViewController controller;
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String?> loadError = ValueNotifier(null);
  bool _autoRetried = false;

  // Guards the localStorage injection + dashboard redirect so they only
  // ever run once, on the tenant's very first page load. Every later
  // onPageFinished is either in-app SPA navigation or our own redirect to
  // /pages/dashboard completing - re-injecting on those would just spam
  // localStorage writes, and re-redirecting on the dashboard's own
  // onPageFinished would loop forever.
  bool _sessionInjected = false;

  _TenantWebViewHolder(this.tenant, this.session, {required this.onLoggedOut}) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.scaffoldBackground)
      // The web app's own Logout button reloads to /auth/login, which
      // onPageFinished below catches directly. This channel exists only as
      // a fallback for any logout path that instead navigates via the
      // client-side router (History API, no reload) - see
      // _injectLogoutWatcher.
      ..addJavaScriptChannel(
        'CompanionLogoutChannel',
        onMessageReceived: (_) => onLoggedOut(),
      );

    // The web app calls the browser Geolocation API on several pages (e.g.
    // login, attendance). Android's WebView denies that by default even
    // though the Flutter app itself already holds OS-level location
    // permission (see PermissionService) - the two are separate grants.
    // Without this, every page that asks shows "Please enable location
    // access" inside the WebView regardless of the device's real
    // permission state.
    if (Platform.isAndroid) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return const GeolocationPermissionsResponse(
            allow: true,
            retain: true,
          );
        },
      );

      // The web app's SKU LOOK-UP "Scan QR Code" feature calls
      // getUserMedia() for camera access. Android WebView denies that by
      // default (same underlying gap as geolocation above), which leaves
      // the scanner stuck on "Starting camera..." forever. Grant whatever
      // media types the page actually asked for (camera and/or mic).
      androidController.setOnPlatformPermissionRequest(
        (request) async {
          await request.grant();
        },
      );
    }

    controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            isLoading.value = true;
            loadError.value = null;
          },
          onPageFinished: (url) async {
            isLoading.value = false;
            // Deliberately NOT resetting _autoRetried here: Android's
            // WebView still fires onPageFinished for its own native error
            // page after a failed navigation (the load "completed", just
            // with an error page as content) - resetting the flag on every
            // onPageFinished caused an infinite silent-retry loop, since
            // each failed retry's error page finishing reset it right
            // back to false before the next onWebResourceError could ever
            // reach the "show the real error UI" branch.
            if (!_sessionInjected) {
              _sessionInjected = true;
              await _injectSessionAndGoToDashboard();
              return; // the dashboard page's own onPageFinished follows
            }
            // The web app's Logout button turns out to trigger a real page
            // reload to /auth/login (not pure client-side routing, as
            // first assumed) - so it's caught here immediately, the moment
            // the reload completes, rather than waiting for the next tick
            // of the JS poll below (which left a ~2s window where the web
            // login page was visibly showing before the native swap).
            if (Uri.parse(url).path.startsWith('/auth/login')) {
              onLoggedOut();
              return;
            }
            // Re-injected on every page load after the dashboard redirect,
            // not just once: the script itself no-ops if already installed
            // in the current page's JS context, but a real page reload
            // wipes that context out. Kept as a fallback for any
            // client-side-only navigation to the login route that this
            // onPageFinished check wouldn't see at all.
            await _injectLogoutWatcher();
          },
          onWebResourceError: (error) {
            isLoading.value = false;
            // A cold LAN connection sometimes times out on the very first
            // attempt; retry silently once before bothering the user with
            // an error screen.
            if (!_autoRetried) {
              _autoRetried = true;
              Future.delayed(const Duration(milliseconds: 800), () {
                controller.reload();
              });
              return;
            }
            loadError.value = error.description;
          },
        ),
      )
      ..loadRequest(Uri.parse(tenant.tenantUrl));
  }

  /// Writes the already-authenticated session into the tenant's own
  /// localStorage (same keys the web app's normal login page sets) and
  /// then navigates straight to the dashboard, so the web app's existing
  /// auth gate - which only ever checks localStorage - treats this as a
  /// signed-in session without ever seeing its own login page.
  Future<void> _injectSessionAndGoToDashboard() async {
    final entries = session.toLocalStorageEntries();
    final statements = entries.entries
        .map((e) => "localStorage.setItem('${e.key}', ${jsonEncode(e.value)});")
        .join('\n');

    try {
      await controller.runJavaScript(statements);
    } catch (_) {
      // If injection fails the WebView just shows the tenant's own login
      // page - a safe fallback, not a broken state.
      return;
    }

    final tenantUri = Uri.parse(tenant.tenantUrl);
    final dashboardUri = tenantUri.replace(
      path: '/pages/dashboard',
      query: '',
      fragment: '',
    );
    await controller.loadRequest(dashboardUri);
  }

  /// Fallback for _handleWebLogout's normal path (a real page reload,
  /// caught directly in onPageFinished): installs a small poll inside the
  /// dashboard page's own JS that watches for the URL becoming the web
  /// app's login route and reports it back over CompanionLogoutChannel, in
  /// case some logout path instead navigates via the client-side router
  /// (History API pushState, which no WebView navigation callback observes).
  Future<void> _injectLogoutWatcher() async {
    const script = '''
(function() {
  if (window.__companionLogoutWatcherInstalled) return;
  window.__companionLogoutWatcherInstalled = true;
  setInterval(function() {
    if (window.location.pathname.indexOf('/auth/login') === 0) {
      CompanionLogoutChannel.postMessage('logout');
    }
  }, 300);
})();
''';
    try {
      await controller.runJavaScript(script);
    } catch (_) {
      // Non-fatal: worst case, logout just leaves the WebView on the web
      // app's own login page instead of returning to the native one.
    }
  }

  void retry() {
    loadError.value = null;
    isLoading.value = true;
    _autoRetried = true; // manual retry shouldn't trigger another silent one
    controller.reload();
  }
}

class _TenantWebView extends StatelessWidget {
  final _TenantWebViewHolder holder;

  const _TenantWebView({required this.holder});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: holder.loadError,
          builder: (context, error, _) {
            if (error == null) {
              return WebViewWidget(controller: holder.controller);
            }
            return Center(
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
                      'Could not load the dashboard.\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: holder.retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: holder.isLoading,
          builder: (context, loading, _) {
            if (!loading) return const SizedBox.shrink();
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          },
        ),
      ],
    );
  }
}
