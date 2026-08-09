import 'location_helper_stub.dart'
    if (dart.library.html) 'location_helper_web.dart';

Future<Map<String, double>?> getWebLocation() => getCurrentWebCoordinates();
