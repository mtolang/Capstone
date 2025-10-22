# Enhanced Weekly Schedule Status System

## Overview
The Clinic Patient List features an intelligent status system that calculates patient status based on:
- **Weekly Contract Schedule** from AcceptedBooking database (Monday-Sunday cycle)
- **OT Assessment Completion** from OTAssessments database  
- **Day-of-Week Logic** (not just time-based)

## Status Logic (Weekly Reset)

### 🟠 Upcoming
- **Criteria**: Appointment day hasn't arrived yet this week
- **Example**: Today is Thursday, appointment is on Friday
- **Logic**: `currentDayOfWeek < appointmentDayOfWeek`

### � Today (Dark Orange)
- **Criteria**: Today is the appointment day but session hasn't started
- **Example**: Today is Friday, appointment at 2 PM, current time is 10 AM
- **Logic**: `currentDayOfWeek == appointmentDayOfWeek && now < appointmentTime`

### 🟢 In Session (Dark Green)
- **Criteria**: Currently during the scheduled appointment time
- **Example**: Appointment 2-3 PM, current time is 2:30 PM
- **Logic**: `appointmentTime <= now < sessionEndTime`

### 🟢 Active
- **Criteria**: Appointment day has passed but no assessment completed yet
- **Example**: Appointment was Monday/Tuesday, today is Wednesday, no assessment
- **Logic**: `currentDayOfWeek > appointmentDayOfWeek && !hasAssessment`

### 🔴 Needs Assessment
- **Criteria**: Session ended today but OT assessment is pending
- **Example**: Session ended at 3 PM today, no assessment recorded
- **Logic**: `sessionEnded && !hasAssessment`

### 🔵 Completed
- **Criteria**: OT assessment has been completed for this week
- **Example**: Patient attended session and assessment was recorded
- **Logic**: `hasCompletedAssessment == true`

## Database Integration

### OTAssessments Matching
The system now uses **dual matching logic** to link assessments:

1. **Primary**: Match by `childName` and `clinicId`
   ```dart
   .where('childName', isEqualTo: childName)
   .where('clinicId', isEqualTo: _clinicId)
   ```

2. **Fallback**: Match by `patientId` and `clinicId` 
   ```dart
   .where('patientId', isEqualTo: patientId)
   .where('clinicId', isEqualTo: _clinicId)
   ```

### Data Examples

**AcceptedBooking**:
```javascript
{
  childName: "Taylor",
  contractInfo: {
    dayOfWeek: "Friday",
    appointmentTime: "14:00 - 15:00"
  },
  parentInfo: {
    parentId: "ParAcc08"
  }
}
```

**OTAssessments**:
```javascript
{
  childName: "Taylor",
  clinicId: "CLI01",
  patientId: "8w6zR8geEnesJ0U4pNbz",
  createdAt: "October 23, 2025"
}
```

## Weekly Reset Logic

### Monday Reset
- All statuses recalculate based on new week
- Previous week's assessments carry over
- New appointment dates calculated from contract schedule

### Status Flow Example (Friday Appointments)
- **Monday-Thursday**: Status = "Upcoming" 
- **Friday Before Session**: Status = "Today"
- **Friday During Session**: Status = "In Session"
- **Friday After Session (No Assessment)**: Status = "Needs Assessment"
- **Friday After Session (With Assessment)**: Status = "Completed"
- **Saturday-Sunday**: Status = "Completed" or "Active"

## Technical Implementation

### Enhanced Assessment Checking
```dart
// Primary matching by name (most reliable)
final nameQuery = await FirebaseFirestore.instance
    .collection('OTAssessments')
    .where('childName', isEqualTo: childName)
    .where('clinicId', isEqualTo: _clinicId)
    .get();

// Fallback matching by ID
if (nameQuery.docs.isEmpty) {
    final idQuery = await FirebaseFirestore.instance
        .collection('OTAssessments')
        .where('patientId', isEqualTo: patientId)
        .where('clinicId', isEqualTo: _clinicId)
        .get();
}
```

### Day-of-Week Calculation
```dart
final currentDayOfWeek = DateTime.now().weekday; // 1=Monday, 7=Sunday
final appointmentDayNumber = _getDayNumber(contractDayOfWeek);

if (currentDayOfWeek < appointmentDayNumber) {
    return 'upcoming';
} else if (currentDayOfWeek > appointmentDayNumber) {
    return hasAssessment ? 'completed' : 'active';
}
```

## User Interface Updates

### Status Colors
- 🟠 **Upcoming**: `Colors.orange`
- 🟠 **Today**: `Colors.orange[600]` (darker orange)
- 🟢 **Active**: `Colors.green`
- 🟢 **In Session**: `Colors.green[600]` (darker green)
- 🔴 **Needs Assessment**: `Colors.red[400]`
- 🔵 **Completed**: `Colors.blue`

### Real-time Updates
- Status badges update automatically as days progress
- No manual intervention required
- Assessments immediately change status to "Completed"

## Benefits for Your Use Case

### Problem Solved
- **Taylor**: Was showing "Active" despite having an assessment
- **Root Cause**: Assessment matching failed due to different ID systems
- **Solution**: Dual matching by name AND ID ensures reliable detection

### Weekly Schedule Clarity
- **Thursday**: Friday appointments show "Upcoming"
- **Friday**: Clear progression from "Today" → "In Session" → "Completed/Needs Assessment"
- **Monday-Wednesday**: Past appointments show proper status based on assessment completion

### Assessment Tracking
- Immediate visual feedback when assessments are completed
- Clear indicators for missing assessments
- Automated weekly reset maintains accuracy