import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final DateTime? time;
  final bool isAllDay;
  final String location;
  final String description;
  final String category;

  Event({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    required this.isAllDay,
    required this.location,
    required this.description,
    required this.category,
  });

  factory Event.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle Firestore timestamp conversion
    DateTime eventDate;
    if (data['date'] is Timestamp) {
      eventDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      eventDate = DateTime.parse(data['date']);
    } else {
      eventDate = DateTime.now();
    }

    DateTime? eventTime;
    if (data['time'] != null) {
      if (data['time'] is Timestamp) {
        eventTime = (data['time'] as Timestamp).toDate();
      } else if (data['time'] is String) {
        eventTime = DateTime.parse(data['time']);
      }
    }

    return Event(
      id: id,
      title: data['title'] ?? '',
      date: eventDate,
      time: eventTime,
      isAllDay: data['isAllDay'] ?? false,
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    
    if (eventDay == today) {
      return 'Today';
    } else if (eventDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (eventDay.isAfter(today) && eventDay.isBefore(today.add(const Duration(days: 7)))) {
      return _formatWeekday(date);
    } else {
      return _formatDate(date);
    }
  }

  String get formattedTime {
    if (isAllDay) {
      return 'All Day';
    } else if (time != null) {
      return _formatTime(time!);
    } else {
      return '';
    }
  }

  String get formattedDateTime {
    String dateStr = _formatDate(date);
    if (isAllDay) {
      return '$dateStr (All Day)';
    } else if (time != null) {
      return '$dateStr at ${_formatTime(time!)}';
    } else {
      return dateStr;
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'worship':
        return 'Worship';
      case 'community':
        return 'Community';
      case 'education':
        return 'Education';
      case 'meeting':
        return 'Meeting';
      default:
        return 'Other';
    }
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    return eventDay.isAfter(today) || eventDay == today;
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatWeekday(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
} 