import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vivin/model/companion_session_model.dart';
import 'package:vivin/service/companion_api_service.dart';

const _okSession =
    '[{"id":1,"u_Name":"x","token":"t","userTypeId":1,"latlongActive":true,'
    '"latitute":"8.8,9.1","longtitude":"78.1,77.2","geoDistance":"50,100"}]';

void main() {
  group('GeoFenceZone.parseList', () {
    test('single store', () {
      final z = GeoFenceZone.parseList(
        latitudes: '8.80521862',
        longitudes: '78.14495455',
        distances: '50',
      );
      expect(z, hasLength(1));
      expect(z.first.latitude, 8.80521862);
      expect(z.first.longitude, 78.14495455);
      expect(z.first.radiusMeters, 50);
    });

    test('comma-separated multi-store lists are paired by position', () {
      final z = GeoFenceZone.parseList(
        latitudes: '8.8, 9.1',
        longitudes: '78.1,77.2',
        distances: '50,100',
      );
      expect(z, hasLength(2));
      expect(z[1].latitude, 9.1);
      expect(z[1].longitude, 77.2);
      expect(z[1].radiusMeters, 100);
    });

    test('entries with a missing or non-numeric part are dropped', () {
      final z = GeoFenceZone.parseList(
        latitudes: '8.8,abc,9.1',
        longitudes: '78.1,77.2',
        distances: '50,100,200',
      );
      // index 1 has a bad latitude, index 2 has no longitude
      expect(z, hasLength(1));
      expect(z.first.latitude, 8.8);
    });

    test('empty / null input yields no zones (nothing to enforce)', () {
      expect(GeoFenceZone.parseList(), isEmpty);
      expect(
        GeoFenceZone.parseList(latitudes: '', longitudes: '', distances: ''),
        isEmpty,
      );
    });
  });

  group('CompanionSession.fromJson geofence', () {
    test('multi-store values are no longer silently dropped', () {
      final s = CompanionSession.fromJson({
        'latlongActive': true,
        'latitute': '8.8,9.1',
        'longtitude': '78.1,77.2',
        'geoDistance': '50,100',
      });
      expect(s.latlongActive, isTrue);
      expect(s.geofences, hasLength(2));
    });
  });

  group('loginWithFirebaseTryingBackends', () {
    test('a 403 stops the fallback and surfaces MobileAccessDenied', () async {
      final called = <String>[];
      final client = MockClient((req) async {
        called.add(req.url.host);
        if (req.url.host == 'a.test') {
          return http.Response('Mobile login not allowed for this user', 403);
        }
        return http.Response(_okSession, 200);
      });

      await http.runWithClient(() async {
        await expectLater(
          CompanionApiService().loginWithFirebaseTryingBackends(
            ['https://a.test/api', 'https://b.test/api'],
            'tok',
          ),
          throwsA(isA<MobileAccessDeniedException>()),
        );
      }, () => client);

      expect(called, ['a.test'], reason: 'second backend must not be tried');
    });

    test('a non-403 failure still falls through to the next backend', () async {
      final client = MockClient((req) async {
        if (req.url.host == 'a.test') return http.Response('nope', 401);
        return http.Response(_okSession, 200);
      });

      late CompanionSession session;
      await http.runWithClient(() async {
        session = await CompanionApiService().loginWithFirebaseTryingBackends(
          ['https://a.test/api', 'https://b.test/api'],
          'tok',
        );
      }, () => client);

      expect(session.token, 't');
    });
  });
}
