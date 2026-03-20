import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:osm_shortlink/osm_shortlink.dart';

void main() {
  group('OsmShortlink', () {
    test('encode/decode parity with random cases', () {
      final random = math.Random(42); // Seed for reproducibility
      final cases = <List<double>>[];
      for (var i = 0; i < 1000; i++) {
        cases.add([
          (180.0 * random.nextDouble()) - 90.0, // lat
          (360.0 * random.nextDouble()) - 180.0, // lon
          (18 * random.nextDouble()).floorToDouble(), // zoom
        ]);
      }

      for (final c in cases) {
        final lat = c[0];
        final lon = c[1];
        final zoom = c[2].toInt();

        final code = OsmShortlink.encode(lon, lat, zoom);
        final decoded = OsmShortlink.decode(code);

        // zooms should be identical
        expect(
          decoded.zoom,
          equals(zoom),
          reason: 'Decoding a encoded short link gives different zoom for ($lat, $lon, $zoom).',
        );

        // location has a quantisation error
        final distance = math.sqrt(
          math.pow(lat - decoded.latitude, 2) + math.pow(lon - decoded.longitude, 2),
        );
        final maxDistance = 360.0 / math.pow(2, zoom + 8) * 0.5 * math.sqrt(5);

        expect(
          distance,
          lessThan(maxDistance),
          reason: 'Maximum expected error exceeded: $maxDistance <= $distance for ($lat, $lon, $zoom).',
        );
      }
    });

    test('deprecated @ sign support', () {
      final cases = [
        ['~v2juONc--', '@v2juONc--'],
        ['as3I3GpG~-', 'as3I3GpG@-'],
        ['D~hV--', 'D@hV--'],
        ['CO0O~m8--', 'CO0O@m8--'],
      ];

      for (final pair in cases) {
        final newCode = pair[0];
        final oldCode = pair[1];

        expect(
          OsmShortlink.decode(oldCode),
          equals(OsmShortlink.decode(newCode)),
          reason: 'old ($oldCode) and new ($newCode) should decode to the same location.',
        );
      }
    });

    group('edge cases', () {
      test('poles', () {
        final northPole = OsmShortlink.encode(0, 89.9, 10);
        final southPole = OsmShortlink.encode(0, -89.9, 10);

        final decodedNorth = OsmShortlink.decode(northPole);
        final decodedSouth = OsmShortlink.decode(southPole);

        expect(decodedNorth.latitude, closeTo(89.9, 0.1));
        expect(decodedSouth.latitude, closeTo(-89.9, 0.1));
      });

      test('anti-meridian', () {
        final west = OsmShortlink.encode(-180, 0, 10);
        final east = OsmShortlink.encode(180, 0, 10);

        final decodedWest = OsmShortlink.decode(west);
        final decodedEast = OsmShortlink.decode(east);

        // Due to wrapping, 180 and -180 might decode to the same thing (usually -180)
        expect(decodedWest.longitude, closeTo(-180, 0.1));
        expect(decodedEast.longitude, closeTo(-180, 0.1));
      });

      test('extreme zoom levels', () {
        final z0 = OsmShortlink.encode(0, 0, 0);
        final z18 = OsmShortlink.encode(0, 0, 18);

        expect(OsmShortlink.decode(z0).zoom, equals(0));
        expect(OsmShortlink.decode(z18).zoom, equals(18));
      });
    });
  });
}
