/// Phone number normalization utilities.
///
/// Implements the normalization standard from the Companion App
/// Flutter + Firebase implementation guide (Section 5): every mobile
/// number is normalized to E.164 before it is used for lookup, login
/// or as an authentication alias seed. Defaults to India (+91) when no
/// country code is present, since that is the primary market today.
class PhoneUtils {
  PhoneUtils._();

  static const String defaultCountryCode = '91';

  /// Normalizes raw user input (e.g. "9840012345", "+91 98400 12345",
  /// "919840012345") into E.164 form, e.g. "+919840012345".
  ///
  /// Returns null if the input does not look like a valid phone number.
  static String? toE164(String rawInput) {
    final digitsOnly = rawInput.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;

    String national;
    if (rawInput.trim().startsWith('+')) {
      // Already has an explicit country code.
      if (digitsOnly.length < 8 || digitsOnly.length > 15) return null;
      return '+$digitsOnly';
    } else if (digitsOnly.length == 10) {
      // Bare national number (India default).
      national = digitsOnly;
      return '+$defaultCountryCode$national';
    } else if (digitsOnly.length == 12 &&
        digitsOnly.startsWith(defaultCountryCode)) {
      // Country code typed without the leading '+'.
      return '+$digitsOnly';
    } else if (digitsOnly.length >= 8 && digitsOnly.length <= 15) {
      // Fallback: accept as-is with a '+' prefix for other formats.
      return '+$digitsOnly';
    }
    return null;
  }

  /// Builds the hidden, deterministic Firebase Auth alias email for a
  /// normalized E.164 mobile number, per Section 4.1 of the guide.
  /// The user never sees or enters this value.
  static String toAuthAlias(String e164Mobile) {
    final digitsOnly = e164Mobile.replaceAll('+', '');
    return '$digitsOnly@auth.companyapp.internal';
  }
}
