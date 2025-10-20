# Clinic Request Management - Bug Fix 🔧

## Problem Identified ❌

The clinic request screen had several critical issues:

1. **No Clinic ID Filtering**: Queries were showing ALL requests from ALL clinics instead of just the logged-in clinic's requests
2. **Missing SharedPreferences**: The screen wasn't retrieving the clinic ID from storage
3. **History Screen Not Receiving Clinic ID**: The history screen couldn't filter by clinic

## Root Cause 🔍

The `clinic_request.dart` was missing the clinic ID context that the therapist version (`ther_request_booking.dart`) already had implemented. This meant:
- Pending requests showed ALL requests system-wide
- History showed ALL requests system-wide
- No user-specific filtering was happening

## Solution Implemented ✅

### 1. Added SharedPreferences Import
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

### 2. Added Clinic ID State Management
```dart
class _ClinicRequestScreenState extends State<ClinicRequestScreen> {
  String? _clinicId;

  @override
  void initState() {
    super.initState();
    _getClinicId();
  }

  Future<void> _getClinicId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _clinicId = prefs.getString('clinic_id') ??
          prefs.getString('user_id') ??
          prefs.getString('therapist_id');
      print('Clinic ID loaded: $_clinicId');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error getting clinic ID: $e');
    }
  }
```

### 3. Updated Pending Requests Query
**Before:**
```dart
stream: FirebaseFirestore.instance
    .collection('Request')
    .where('status', isEqualTo: 'pending')
    .orderBy('appointmentDetails.requestedDate', descending: false)
    .snapshots(),
```

**After:**
```dart
// Added null check
if (_clinicId == null) {
  return const Center(child: CircularProgressIndicator());
}

stream: FirebaseFirestore.instance
    .collection('Request')
    .where('serviceProvider.clinicId', isEqualTo: _clinicId)  // ← NEW
    .where('status', isEqualTo: 'pending')
    .orderBy('appointmentDetails.requestedDate', descending: false)
    .snapshots(),
```

### 4. Updated History Screen to Accept Clinic ID
**Before:**
```dart
class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({Key? key}) : super(key: key);
```

**After:**
```dart
class RequestHistoryScreen extends StatefulWidget {
  final String clinicId;  // ← NEW
  
  const RequestHistoryScreen({Key? key, required this.clinicId}) : super(key: key);
```

### 5. Updated History Navigation
**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RequestHistoryScreen(),
  ),
);
```

**After:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RequestHistoryScreen(clinicId: _clinicId!),
  ),
);
```

### 6. Updated History Query Filter
**Before:**
```dart
Query query = FirebaseFirestore.instance.collection('Request');

if (_selectedFilter == 'approved') {
  query = query.where('status', isEqualTo: 'approved');
} // ...
```

**After:**
```dart
Query query = FirebaseFirestore.instance
    .collection('Request')
    .where('serviceProvider.clinicId', isEqualTo: widget.clinicId);  // ← NEW

if (_selectedFilter == 'approved') {
  query = query.where('status', isEqualTo: 'approved');
} // ...
```

## Database Structure Reference 📊

### Request Collection
```javascript
Request/{requestId} {
  status: "pending" | "approved" | "declined",
  serviceProvider: {
    clinicId: "CLI01",           // ← Filter field for clinics
    therapistId: "TherAcc02"     // (or this for therapists)
  },
  parentInfo: {
    parentName: "John Doe"
  },
  childInfo: {
    childName: "Jane Doe"
  },
  appointmentDetails: {
    requestedDate: Timestamp,
    requestedTime: "09:00 - 10:00",
    appointmentType: "Therapy"
  }
}
```

## How It Works Now ✨

### Pending Requests Screen
1. ✅ Screen loads and retrieves clinic ID from SharedPreferences
2. ✅ Query filters requests where `serviceProvider.clinicId == logged-in clinic ID`
3. ✅ Only shows requests with `status: "pending"`
4. ✅ Shows "No Pending Requests" if empty
5. ✅ History button visible in AppBar

### History Screen
1. ✅ Receives clinic ID as constructor parameter
2. ✅ Base query filters by `serviceProvider.clinicId`
3. ✅ Filter chips work: All / Approved / Declined
4. ✅ Approved requests show green indicators
5. ✅ Declined requests show red indicators
6. ✅ Shows "No History" if no approved/declined requests

## Testing Checklist ✅

- [ ] Login as clinic user
- [ ] Verify pending requests screen shows only YOUR clinic's pending requests
- [ ] Verify other clinics' requests don't appear
- [ ] Click history icon in AppBar
- [ ] Verify history screen opens
- [ ] Test "All" filter - should show all approved + declined for your clinic
- [ ] Test "Approved" filter - should show only approved
- [ ] Test "Declined" filter - should show only declined
- [ ] Verify status badges are color-coded correctly:
  - 🟠 Orange for pending
  - ✅ Green for approved
  - ❌ Red for declined

## Files Modified 📝

1. **lib/screens/clinic/clinic_request.dart**
   - Added SharedPreferences import
   - Added clinic ID state management
   - Added `_getClinicId()` method
   - Updated pending requests query with clinic ID filter
   - Updated history screen to accept clinic ID parameter
   - Updated history query with clinic ID filter

## Comparison with Therapist Version 🔄

Both screens now follow the same pattern:
- ✅ Load user ID from SharedPreferences in initState
- ✅ Filter queries by user ID
- ✅ Show loading indicator while ID loads
- ✅ History screen receives user ID as parameter
- ✅ All queries properly scoped to logged-in user

## Expected Behavior 🎯

**Clinic Dashboard → Requests Tab:**
- Shows ONLY pending requests for the logged-in clinic
- History icon visible in AppBar
- Clean, focused view

**History Screen:**
- Shows approved and declined requests for the logged-in clinic
- Filter chips to toggle between All/Approved/Declined
- Color-coded status indicators
- No pending requests (they're in the main screen)

## Debug Console Output 🖥️

When the screen loads, you should see:
```
Clinic ID loaded: CLI01
```

If this doesn't appear, check:
1. User is logged in
2. Clinic ID was stored during login
3. SharedPreferences key is 'clinic_id', 'user_id', or 'therapist_id'

## Firestore Indexes Required 🗂️

You may need to create composite indexes for:

1. **Pending Requests Query:**
   - Collection: `Request`
   - Fields: `serviceProvider.clinicId` (Ascending), `status` (Ascending), `appointmentDetails.requestedDate` (Ascending)

2. **History All Query:**
   - Collection: `Request`
   - Fields: `serviceProvider.clinicId` (Ascending), `status` (Array), `appointmentDetails.requestedDate` (Descending)

3. **History Approved Query:**
   - Collection: `Request`
   - Fields: `serviceProvider.clinicId` (Ascending), `status` (Ascending), `appointmentDetails.requestedDate` (Descending)

4. **History Declined Query:**
   - Collection: `Request`
   - Fields: `serviceProvider.clinicId` (Ascending), `status` (Ascending), `appointmentDetails.requestedDate` (Descending)

**Note:** Firebase will provide index creation links in the console if these are missing.

---

**Status:** ✅ Fixed and Ready for Testing  
**Date:** October 19, 2025  
**Impact:** Critical - Ensures proper data isolation between clinics
