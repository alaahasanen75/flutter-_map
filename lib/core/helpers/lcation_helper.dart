import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<Position> getCurrentPosition() async {
    final bool isServiceEnable = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnable) {
      await Geolocator.requestPermission();
    }

    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
