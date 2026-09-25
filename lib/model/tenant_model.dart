/// A tenant's registry entry — mirrors the `tenantMaster/{tenantId}`
/// Firestore document.
class TenantMaster {
  final String tenantId;
  final String tenantName;
  final String tenantStatus;
  final String tenantUrl;
  // The companionAPI backend this tenant's login/session calls go through.
  // Tenants normally share one backend (e.g. SATHYA/TESTCO), but a tenant
  // with its own separate companiondb (e.g. Unilet) has its own here.
  final String apiBaseUrl;

  const TenantMaster({
    required this.tenantId,
    required this.tenantName,
    required this.tenantStatus,
    required this.tenantUrl,
    required this.apiBaseUrl,
  });

  bool get isActive => tenantStatus.toUpperCase() == 'ACTIVE';

  factory TenantMaster.fromMap(String tenantId, Map<String, dynamic> map) {
    return TenantMaster(
      tenantId: tenantId,
      tenantName: map['tenantName'] as String? ?? tenantId,
      tenantStatus: map['tenantStatus'] as String? ?? 'INACTIVE',
      tenantUrl: map['tenantUrl'] as String? ?? '',
      apiBaseUrl: map['apiBaseUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'tenantId': tenantId,
        'tenantName': tenantName,
        'tenantStatus': tenantStatus,
        'tenantUrl': tenantUrl,
        'apiBaseUrl': apiBaseUrl,
      };
}
