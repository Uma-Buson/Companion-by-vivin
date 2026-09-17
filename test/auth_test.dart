import 'package:flutter_test/flutter_test.dart';
import 'package:vivin/utils/phone_utils.dart';

void main() {
  group('PhoneUtils.toE164', () {
    test('Bare 10-digit national number gets India country code', () {
      expect(PhoneUtils.toE164('9840012345'), equals('+919840012345'));
    });

    test('Number already in E.164 format is preserved', () {
      expect(PhoneUtils.toE164('+919840012345'), equals('+919840012345'));
    });

    test('Formatted number with spaces is normalized', () {
      expect(PhoneUtils.toE164('+91 98400 12345'), equals('+919840012345'));
    });

    test('Country code typed without leading + is normalized', () {
      expect(PhoneUtils.toE164('919840012345'), equals('+919840012345'));
    });

    test('Empty input is rejected', () {
      expect(PhoneUtils.toE164(''), isNull);
    });

    test('Too-short input is rejected', () {
      expect(PhoneUtils.toE164('12345'), isNull);
    });
  });

  group('PhoneUtils.toAuthAlias', () {
    test('Builds the hidden deterministic auth alias email', () {
      expect(
        PhoneUtils.toAuthAlias('+919840012345'),
        equals('919840012345@auth.companyapp.internal'),
      );
    });
  });
}
