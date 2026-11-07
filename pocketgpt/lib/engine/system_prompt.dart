import '../models/chat_message.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _two(int n) => n.toString().padLeft(2, '0');

String _clock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String _offset(Duration d) {
  final sign = d.isNegative ? '-' : '+';
  final abs = d.abs();
  return 'UTC$sign${_two(abs.inHours)}:${_two(abs.inMinutes.remainder(60))}';
}

/// Hidden first message that tells the model the real date, time and its
/// limits. It is sent to the engine on every request but never shown or saved.
ChatMessage buildSystemMessage(DateTime now) {
  final date = '${_weekdays[now.weekday - 1]}, ${now.day} '
      '${_months[now.month - 1]} ${now.year}';
  final utc = now.toUtc();
  return ChatMessage(
    'system',
    'You are PocketGPT, a helpful assistant running offline on the user\'s '
        'own device.\n'
        'CURRENT DATE AND TIME (from the user\'s device clock, always correct): '
        '$date, ${_clock(now)} (24-hour clock), ${_offset(now.timeZoneOffset)}. '
        'In UTC it is ${_clock(utc)} on ${utc.day} ${_months[utc.month - 1]} '
        '${utc.year}.\n'
        'Rules: Trust this date and time over anything you remember from '
        'training, and never tell the user their date is wrong. You have no '
        'internet access and your training knowledge ends before this date, so '
        'say so when asked about recent events. If asked for the time in another '
        'place, work it out from the UTC time above and show the calculation; if '
        'you are not sure of that place\'s UTC offset or daylight saving rules, '
        'say so instead of guessing.',
  );
}
