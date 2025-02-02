import '../l10n/app_localizations.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        return AppLocalizations.get('minutesAgo', args: {'count': minutes.toString()});
      } else {
        final hours = difference.inHours;
        return AppLocalizations.get('hoursAgo', args: {'count': hours.toString()});
      }
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return AppLocalizations.get('daysAgo', args: {'count': days.toString()});
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    }
  }

  static String formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hours = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      return '$hours:$minutes';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return AppLocalizations.get('daysAgo', args: {'count': days.toString()});
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    }
  }

  static String formatTimeAgo(DateTime date) {
    return AppLocalizations.formatTimeAgo(date);
  }
}
