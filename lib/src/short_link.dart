import 'dart:math' as math;

/// A class that implements the OpenStreetMap Shortlink algorithm.
///
/// Ported from the original Ruby implementation in the OSM core.
class OsmShortlink {
  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~';

  /// Decodes a shortlink string into a [ShortlinkLocation].
  ///
  /// The [str] can use either the modern '~' or the legacy '@' character.
  static ShortlinkLocation decode(String str) {
    int x = 0;
    int y = 0;
    int z = 0;
    int zOffset = 0;

    // Support legacy '@' character
    final normalizedStr = str.replaceAll('@', '~');

    for (int i = 0; i < normalizedStr.length; i++) {
      final char = normalizedStr[i];
      int t = _alphabet.indexOf(char);

      if (t == -1) {
        zOffset -= 1;
      } else {
        for (int j = 0; j < 3; j++) {
          x <<= 1;
          if ((t & 32) != 0) {
            x |= 1;
          }
          t <<= 1;

          y <<= 1;
          if ((t & 32) != 0) {
            y |= 1;
          }
          t <<= 1;
        }
        z += 3;
      }
    }

    // Pack the coordinates out to their original 32 bits.
    // Use BigInt logic or bit manipulation to avoid overflow issues if z < 32
    // Actually in Dart, ints are 64-bit, so x << (32 - z) is fine if x fits.
    // x and y were built as z-bit integers.
    x <<= (32 - z);
    y <<= (32 - z);

    // project parameters back to their coordinate ranges.
    // We use long double-like precision with 64-bit ints.
    final double longitude = (x.toDouble() * 360.0 / math.pow(2, 32)) - 180.0;
    final double latitude = (y.toDouble() * 180.0 / math.pow(2, 32)) - 90.0;
    final int zoom = z - 8 - (zOffset % 3);

    return ShortlinkLocation(
      longitude: longitude,
      latitude: latitude,
      zoom: zoom,
    );
  }

  /// Encodes a location and zoom level into a shortlink string.
  static String encode(double longitude, double latitude, int zoom) {
    final int x = ((longitude + 180.0) * math.pow(2, 32) / 360.0).floor() & 0xFFFFFFFF;
    final int y = ((latitude + 90.0) * math.pow(2, 32) / 180.0).floor() & 0xFFFFFFFF;

    final BigInt code = _interleaveBits(x, y);
    final buffer = StringBuffer();

    // add eight to the zoom level, which approximates an accuracy of
    // one pixel in a tile.
    final int charCount = ((zoom + 8) / 3.0).ceil();
    for (int i = 0; i < charCount; i++) {
      // digit = (code >> (58 - (6 * i))) & 0x3f
      final int shift = 58 - (6 * i);
      final int digit = (code >> shift).toUnsigned(6).toInt();
      buffer.write(_alphabet[digit]);
    }

    // append characters onto the end of the string to represent
    // partial zoom levels
    final int partialZoom = (zoom + 8) % 3;
    for (int i = 0; i < partialZoom; i++) {
      buffer.write('-');
    }

    return buffer.toString();
  }

  /// Interleaves the bits of two 32-bit numbers.
  /// Result is a 64-bit Morton code.
  static BigInt _interleaveBits(int x, int y) {
    BigInt c = BigInt.zero;
    for (int i = 31; i >= 0; i--) {
      c = (c << 1) | BigInt.from((x >> i) & 1);
      c = (c << 1) | BigInt.from((y >> i) & 1);
    }
    return c;
  }
}

/// Represents a geographic location and zoom level decoded from a shortlink.
class ShortlinkLocation {
  final double longitude;
  final double latitude;
  final int zoom;

  const ShortlinkLocation({
    required this.longitude,
    required this.latitude,
    required this.zoom,
  });

  @override
  String toString() => 'ShortlinkLocation(lon: $longitude, lat: $latitude, zoom: $zoom)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortlinkLocation &&
          runtimeType == other.runtimeType &&
          longitude == other.longitude &&
          latitude == other.latitude &&
          zoom == other.zoom;

  @override
  int get hashCode => longitude.hashCode ^ latitude.hashCode ^ zoom.hashCode;
}
