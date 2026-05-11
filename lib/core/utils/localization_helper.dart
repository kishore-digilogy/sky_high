import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';

class LocalizationHelper {
  static String getLocalized(Map<String, dynamic> json, String baseKey) {
    if (!GetIt.I.isRegistered<StorageService>()) return json[baseKey]?.toString() ?? '';
    
    final language = GetIt.I<StorageService>().getSelectedLanguage();
    String? suffix;
    switch (language) {
      case 'Tamil':
        suffix = '_ta';
        break;
      case 'Telugu':
        suffix = '_te';
        break;
      case 'Hindi':
        suffix = '_hi';
        break;
      case 'Malayalam':
        suffix = '_ml';
        break;
      case 'Kannada':
        suffix = '_kn';
        break;
      default:
        suffix = null;
    }

    if (suffix != null &&
        json['$baseKey$suffix'] != null &&
        json['$baseKey$suffix'].toString().isNotEmpty) {
      return json['$baseKey$suffix'].toString();
    }
    return json[baseKey]?.toString() ?? '';
  }
}
