import 'package:osm_shortlink/osm_shortlink.dart';

void main() {
  // Berlin Brandenburg Gate
  const double lon = 13.3777;
  const double lat = 52.5163;
  const int zoom = 17;

  // Encode to shortlink
  final String code = OsmShortlink.encode(lon, lat, zoom);
  print('Location: $lat, $lon at zoom $zoom');
  print('Shortlink: https://osm.org/go/$code');

  // Decode back
  final ShortlinkLocation decoded = OsmShortlink.decode(code);
  print('Decoded: ${decoded.latitude}, ${decoded.longitude} at zoom ${decoded.zoom}');
}
