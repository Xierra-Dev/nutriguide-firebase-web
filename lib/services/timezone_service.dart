import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  static bool _initialized = false;

  static void initializeTimeZones() {
    if (!_initialized) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      _initialized = true;
      print('Timezone initialized successfully');
    }
  }
}