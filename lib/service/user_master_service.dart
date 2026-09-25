import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/user_master_model.dart';
import '../utils/phone_utils.dart';

/// Looks up the phone-number-first login gate document. This is a direct,
/// public Firestore read (see security rules: UserMaster only allows a
/// "get" by known doc ID, never a "list") - it only ever returns
/// non-secret fields (name, loginType), so it's safe to read before the
/// user is signed in to Firebase Auth at all.
class UserMasterService {
  static final UserMasterService _instance = UserMasterService._internal();
  factory UserMasterService() => _instance;
  UserMasterService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Returns null if no UserMaster record exists for this phone number.
  Future<UserMaster?> lookup(String rawMobileNo) async {
    final e164 = PhoneUtils.toE164(rawMobileNo);
    if (e164 == null) return null;

    final digits = e164.replaceAll('+', '');
    final national10 = digits.length > 10 ? digits.substring(digits.length - 10) : digits;

    final snap = await _db.collection('UserMaster').doc(national10).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserMaster.fromMap(national10, snap.data()!);
  }
}
