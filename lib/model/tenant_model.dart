/// A tenant's registry entry — mirrors the `tenantMaster/{tenantId}`
/// Firestore document.
class TenantMaster {
  final String tenantId;
  final String tenantName;
  final String tenantStatus;
  final String tenantUrl;

  const TenantMaster({
    required this.tenantId,
    required this.tenantName,
    required this.tenantStatus,
    required this.tenantUrl,
  });

  bool get isActive => tenantStatus.toUpperCase() == 'ACTIVE';

  factory TenantMaster.fromMap(String tenantId, Map<String, dynamic> map) {
    return TenantMaster(
      tenantId: tenantId,
      tenantName: map['tenantName'] as String? ?? tenantId,
      tenantStatus: map['tenantStatus'] as String? ?? 'INACTIVE',
      tenantUrl: map['tenantUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'tenantId': tenantId,
        'tenantName': tenantName,
        'tenantStatus': tenantStatus,
        'tenantUrl': tenantUrl,
      };
}
