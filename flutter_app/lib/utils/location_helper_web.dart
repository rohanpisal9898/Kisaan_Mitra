// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<Map<String, double>?> getCurrentWebCoordinates() async {
  try {
    final pos = await html.window.navigator.geolocation.getCurrentPosition();
    if (pos.coords != null) {
      final lat = (pos.coords!.latitude as num).toDouble();
      final lon = (pos.coords!.longitude as num).toDouble();
      return {'latitude': lat, 'longitude': lon};
    }
  } catch (_) {}
  return null;
}
