import 'app_fr.dart';

class AppLocalizations {
  static const String _defaultLocale = 'fr';
  
  static String get(String key, {Map<String, String>? args}) {
    String value = AppLocaleFr.values[key] ?? key;
    
    if (args != null) {
      args.forEach((argKey, argValue) {
        value = value.replaceAll('{$argKey}', argValue);
      });
    }
    
    return value;
  }

  static String pluralize(String key, int count) {
    return get(count == 1 ? '${key}Ago' : '${key}sAgo', 
      args: {'count': count.toString()});
  }

  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return get('justNow');
    } else if (difference.inHours < 1) {
      return pluralize('minute', difference.inMinutes);
    } else if (difference.inDays < 1) {
      return pluralize('hour', difference.inHours);
    } else if (difference.inDays < 7) {
      return pluralize('day', difference.inDays);
    } else if (difference.inDays < 30) {
      return pluralize('week', (difference.inDays / 7).floor());
    } else if (difference.inDays < 365) {
      return pluralize('month', (difference.inDays / 30).floor());
    } else {
      return pluralize('year', (difference.inDays / 365).floor());
    }
  }
}
