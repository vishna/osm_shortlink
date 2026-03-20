# OsmShortlink

A Dart implementation of the [OpenStreetMap Shortlink](https://wiki.openstreetmap.org/wiki/Shortlink) algorithm.

## Features

- Encode (longitude, latitude, zoom) into a short string.
- Decode a short string back into (longitude, latitude, zoom).
- Compatible with OSM core Ruby implementation.
- Handles the 64-character alphabet (`A-Z`, `a-z`, `0-9`, `_`, `~`).

## Usage

```dart
import 'package:osm_shortlink/osm_shortlink.dart';

void main() {
  final lon = 13.4067;
  final lat = 52.5222;
  final zoom = 15;

  final code = OsmShortlink.encode(lon, lat, zoom);
  print('Shortlink: $code');

  final decoded = OsmShortlink.decode(code);
  print('Decoded: ${decoded.longitude}, ${decoded.latitude}, ${decoded.zoom}');
}
```

## Algorithm

The algorithm uses Morton coding (interleaving bits) to combine longitude and latitude into a single 64-bit integer, which is then encoded using a modified Base64 alphabet. Each character represents 3 bits of longitude and 3 bits of latitude (6 bits total).
