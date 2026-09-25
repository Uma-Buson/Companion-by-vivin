import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/tenant_model.dart';
import 'fcm_service.dart';

/// Manages the Firestore-side tenant registry, tenant/user mapping, and
/// per-tenant FCM log described in the Companion App architecture:
///
/// - `tenantMaster/{tenantId}` — tenant registry (name, status, web URL)
/// - `tenantMapping/{uid}_{tenantId}` — which Firebase users belong to
///   which tenant
/// - `userLog/{uid}_{tenantId}` — FCM token scoped per (user, tenant), so
///   pushes can target a specific tenant's users
///
/// A user's tenant mappings are granted out-of-band (an admin script writes
/// `tenantMapping` rows directly, the same way tenants themselves are
/// seeded) — the app never auto-creates a mapping for itself. It only
/// reads whichever mappings already exist for the signed-in user.
class TenantService {
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tenantMaster =>
      _db.collection('tenantMaster');

  CollectionReference<Map<String, dynamic>> get _tenantMapping =>
      _db.collection('tenantMapping');

  CollectionReference<Map<String, dynamic>> get _userLog =>
      _db.collection('userLog');

  String _mappingDocId(String uid, String tenantId) => '${uid}_$tenantId';

  Future<TenantMaster?> getTenantMaster(String tenantId) async {
    final snap = await _tenantMaster.doc(tenantId).get();
    if (!snap.exists || snap.data() == null) return null;
    return TenantMaster.fromMap(tenantId, snap.data()!);
  }

  Future<void> deleteMapping(String uid, String tenantId) async {
    await _tenantMapping.doc(_mappingDocId(uid, tenantId)).delete();
  }

  Future<void> upsertUserLog(
    String uid,
    String tenantId,
    String tenantName,
  ) async {
    final fcmToken = FcmService().fcmToken;
    await _userLog.doc(_mappingDocId(uid, tenantId)).set({
      'uid': uid,
      'tenantName': tenantName,
      'fcm': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Returns every tenant [uid] currently has Active access to, driven
  /// entirely by whatever `tenantMapping` rows already exist for them.
  ///
  /// Self-heals as it goes: a mapping pointing at a tenant that is now
  /// Inactive (or was deleted from `tenantMaster` entirely) is removed
  /// rather than surfaced, matching the original single-tenant behaviour.
  /// Also refreshes this device's FCM token in `userLog` for every tenant
  /// still found Active, so pushes can reach the user under any tenant
  /// they belong to — not just the one they open right now.
  Future<List<TenantMaster>> getActiveTenantsForUser(String uid) async {
    final mappingsSnap =
        await _tenantMapping.where('uid', isEqualTo: uid).get();

    final active = <TenantMaster>[];
    for (final doc in mappingsSnap.docs) {
      final tenantId = doc.data()['tenantId'] as String?;
      if (tenantId == null) continue;

      final tenant = await getTenantMaster(tenantId);
      if (tenant == null || !tenant.isActive) {
        await doc.reference.delete();
        continue;
      }

      active.add(tenant);
      await upsertUserLog(uid, tenantId, tenant.tenantName);
    }
    return active;
  }
}






