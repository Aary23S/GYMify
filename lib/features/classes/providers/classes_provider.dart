import 'package:flutter_riverpod/flutter_riverpod.dart';

class GymClassSession {
  final String id;
  final String className;
  final String category; // 'Yoga', 'HIIT', 'Zumba', 'CrossFit', 'Spinning'
  final DateTime date;
  final String startTime;
  final String endTime;
  final String trainerName;
  final String location;
  final int maxSpots;
  final Set<String> bookedMemberIds;

  GymClassSession({
    required this.id,
    required this.className,
    required this.category,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.trainerName,
    required this.location,
    required this.maxSpots,
    required this.bookedMemberIds,
  });

  bool isBookedBy(String memberId) => bookedMemberIds.contains(memberId);
  bool get isFull => bookedMemberIds.length >= maxSpots;

  GymClassSession copyWith({
    String? id,
    String? className,
    String? category,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? trainerName,
    String? location,
    int? maxSpots,
    Set<String>? bookedMemberIds,
  }) {
    return GymClassSession(
      id: id ?? this.id,
      className: className ?? this.className,
      category: category ?? this.category,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      trainerName: trainerName ?? this.trainerName,
      location: location ?? this.location,
      maxSpots: maxSpots ?? this.maxSpots,
      bookedMemberIds: bookedMemberIds ?? this.bookedMemberIds,
    );
  }
}

class ClassesNotifier extends StateNotifier<List<GymClassSession>> {
  ClassesNotifier() : super(_initialSessions());

  static List<GymClassSession> _initialSessions() {
    final now = DateTime.now();
    final List<GymClassSession> sessions = [];

    final classTemplates = [
      {'name': 'Morning Yoga Flow', 'cat': 'Yoga', 'start': '07:00 AM', 'end': '08:00 AM', 'trainer': 'Sneha Kapoor', 'loc': 'Studio A'},
      {'name': 'HIIT Cardio Blast', 'cat': 'HIIT', 'start': '08:30 AM', 'end': '09:30 AM', 'trainer': 'Vikram Singh', 'loc': 'Main Floor'},
      {'name': 'Zumba Dance Party', 'cat': 'Zumba', 'start': '10:00 AM', 'end': '11:00 AM', 'trainer': 'Ananya Iyer', 'loc': 'Studio B'},
      {'name': 'CrossFit Warriors', 'cat': 'CrossFit', 'start': '05:00 PM', 'end': '06:00 PM', 'trainer': 'Kabir Das', 'loc': 'Rig Area'},
      {'name': 'Spinning Endurance', 'cat': 'Spinning', 'start': '06:30 PM', 'end': '07:30 PM', 'trainer': 'Rahul Khanna', 'loc': 'Cycling Deck'},
      {'name': 'Sunset Yin Yoga', 'cat': 'Yoga', 'start': '07:30 PM', 'end': '08:30 PM', 'trainer': 'Sneha Kapoor', 'loc': 'Studio A'},
    ];

    int idCounter = 1;
    // Generate classes for today and next 7 days
    for (int dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
      
      for (var t in classTemplates) {
        // Pre-book some dummy members
        final Set<String> preBooked = {'2', '3', '5'};
        // For today's morning yoga and hiit, book member '1' (our logged-in member)
        if (dayOffset == 0 && (t['cat'] == 'Yoga' || t['cat'] == 'HIIT')) {
          preBooked.add('1');
        } else if (dayOffset == 1 && t['cat'] == 'Zumba') {
          preBooked.add('1');
        } else if (dayOffset == 3 && t['cat'] == 'CrossFit') {
          preBooked.add('1');
        }

        sessions.add(GymClassSession(
          id: 'CLS-$idCounter',
          className: t['name']!,
          category: t['cat']!,
          date: targetDate,
          startTime: t['start']!,
          endTime: t['end']!,
          trainerName: t['trainer']!,
          location: t['loc']!,
          maxSpots: 20,
          bookedMemberIds: preBooked,
        ));
        idCounter++;
      }
    }
    return sessions;
  }

  void bookClass(String sessionId, String memberId) {
    state = state.map((s) {
      if (s.id == sessionId) {
        final updated = Set<String>.from(s.bookedMemberIds)..add(memberId);
        return s.copyWith(bookedMemberIds: updated);
      }
      return s;
    }).toList();
  }

  void cancelBooking(String sessionId, String memberId) {
    state = state.map((s) {
      if (s.id == sessionId) {
        final updated = Set<String>.from(s.bookedMemberIds)..remove(memberId);
        return s.copyWith(bookedMemberIds: updated);
      }
      return s;
    }).toList();
  }
}

final classesProvider = StateNotifierProvider<ClassesNotifier, List<GymClassSession>>((ref) {
  return ClassesNotifier();
});
