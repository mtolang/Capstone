class TimeSlot {
  final String slotId;
  final String time;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final bool isBooked;
  final String patientName;
  final String? patientId;
  final String appointmentType;
  final String notes;

  TimeSlot({
    required this.slotId,
    required this.time,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.isBooked,
    required this.patientName,
    this.patientId,
    required this.appointmentType,
    required this.notes,
  });

  // Factory constructor to create TimeSlot from Firebase data
  factory TimeSlot.fromFirestore(Map<String, dynamic> data) {
    final startTime = data['startTime'] ?? '';
    final endTime = data['endTime'] ?? '';

    return TimeSlot(
      slotId: data['slotId'] ?? '',
      time: '$startTime - $endTime',
      startTime: startTime,
      endTime: endTime,
      isAvailable: data['isAvailable'] ?? true,
      isBooked: data['isBooked'] ?? false,
      patientName: data['patientName'] ?? '',
      patientId: data['patientId'],
      appointmentType: data['appointmentType'] ?? 'therapy',
      notes: data['notes'] ?? '',
    );
  }

  // Convert to map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'slotId': slotId,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      'isBooked': isBooked,
      'patientName': patientName,
      'patientId': patientId,
      'appointmentType': appointmentType,
      'notes': notes,
    };
  }

  // Create a copy with updated values
  TimeSlot copyWith({
    String? slotId,
    String? time,
    String? startTime,
    String? endTime,
    bool? isAvailable,
    bool? isBooked,
    String? patientName,
    String? patientId,
    String? appointmentType,
    String? notes,
  }) {
    return TimeSlot(
      slotId: slotId ?? this.slotId,
      time: time ?? this.time,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      isBooked: isBooked ?? this.isBooked,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      appointmentType: appointmentType ?? this.appointmentType,
      notes: notes ?? this.notes,
    );
  }
}
