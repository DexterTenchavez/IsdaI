import 'package:flutter/material.dart';
import 'app_language.dart';

const List<String> _monthsEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthsTl = [
  'Ene',
  'Peb',
  'Mar',
  'Abr',
  'May',
  'Hun',
  'Hul',
  'Ago',
  'Set',
  'Okt',
  'Nob',
  'Dis',
];

/// "Oct 30, 2026 • 3:45 PM" in the current app language.
String scanDateLabel(BuildContext context, DateTime d) {
  final tagalog = AppLanguageScope.of(context).lang == AppLang.tl;
  final months = tagalog ? _monthsTl : _monthsEn;

  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour >= 12 ? 'PM' : 'AM';

  return '${months[d.month - 1]} ${d.day}, ${d.year} • $hour12:$minute $ampm';
}
