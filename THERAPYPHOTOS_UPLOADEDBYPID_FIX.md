# TherapyPhotos Records Tab Fix - Using uploadedById

## Problem Analysis
The Records tab was showing "No therapy photos" even though TherapyPhotos documents existed. The issue was identified as:

1. **Wrong field matching**: Query was using `parentId` field instead of `uploadedById`
2. **Parent ID extraction**: Needed to improve parent ID extraction from patient data
3. **Data flow mismatch**: Patient list passes parent ID but Records tab wasn't using it correctly

## Solution Implementation

### 1. Updated Query to Use uploadedById
**Before:**
```dart
.where('parentId', isEqualTo: searchParentId)
```

**After:**
```dart
.where('uploadedById', isEqualTo: searchParentId)
```

This matches the TherapyPhotos document structure where:
- `uploadedById`: "ParAcc04" (the parent who uploaded the photo)
- `parentId`: "ParAcc04" (redundant field, but uploadedById is primary)

### 2. Enhanced Parent ID Extraction
Added multiple fallback options for extracting parent ID:

```dart
_parentId = widget.patientData!['originalRequestData']?['parentInfo']?['parentId'] ??
           widget.patientData!['parentId'] ??
           widget.patientData!['parentID'] ??
           widget.patientData!['patientInfo']?['parentId'] ??
           widget.patientData!['id']; // fallback to document ID
```

### 3. Added Helper Method for Parent ID Discovery
```dart
void _findParentIdFromPatientData() {
  // Check if widget.patientId itself is the parent ID
  if (widget.patientId != 'unknown' && widget.patientId.startsWith('ParAcc')) {
    _parentId = widget.patientId;
    return;
  }
  
  // Check additional nested structures
  _parentId = data['parentInfo']?['parentId'] ??
             data['requestData']?['parentInfo']?['parentId'] ??
             data['bookingData']?['parentId'] ??
             data['parent']?['id'];
}
```

## Data Flow Verification

### Patient List → Patient Profile Flow:
1. **Patient List**: Extracts parent ID from AcceptedBooking collection
   ```dart
   final patientId = patient['patientInfo']?['parentId'] ??
                    patient['parentID'] ??
                    patient['id'] ??
                    patient['documentId'] ??
                    'unknown';
   ```

2. **Patient Profile**: Receives parent ID as `widget.patientId`

3. **Info Tab**: Successfully queries ParentsAcc using parent ID ✅

4. **Records Tab**: Now queries TherapyPhotos using `uploadedById` = parent ID ✅

## Expected Database Queries

### Info Tab (Working):
```dart
FirebaseFirestore.instance
  .collection('ParentsAcc')
  .doc(parentId) // e.g., "ParAcc04"
```

### Records Tab (Fixed):
```dart
FirebaseFirestore.instance
  .collection('TherapyPhotos')
  .where('uploadedById', isEqualTo: parentId) // e.g., "ParAcc04"
```

## TherapyPhotos Document Structure Match
The fix now properly matches the provided document structure:

```
Document ID: [auto-generated]
{
  parentId: "ParAcc04"           // Parent reference
  uploadedById: "ParAcc04"       // ✅ Query field (who uploaded)
  childName: "Kurimeow"          // Child reference
  clinicId: "CLI01"              // Clinic reference
  photoUrl: "https://..."        // Photo URL
  associatedMaterialTitle: "tes" // Material association
  associatedMaterialCategory: "motor"
  uploadedAt: Timestamp
  isActive: true
  // ... other fields
}
```

## Debug Output Enhanced
Updated console logging to track:
- Parent ID extraction process
- Query field used (`uploadedById` instead of `parentId`)
- Document filtering results
- Fallback logic execution

## Testing Checklist
- [ ] Parent ID correctly extracted from patient data
- [ ] TherapyPhotos query uses `uploadedById` field
- [ ] Photos display in Records tab for patient "Kurimeow"
- [ ] Full-screen photo viewing works
- [ ] Client-side filtering by `clinicId` and `isActive` functions
- [ ] Debug output shows successful photo retrieval

## Key Changes Summary
1. **Query Field**: `parentId` → `uploadedById`
2. **Parent ID Extraction**: Enhanced with multiple fallbacks
3. **Helper Method**: Added `_findParentIdFromPatientData()`
4. **Debug Logging**: Updated to reflect new query approach
5. **Fallback Strategy**: Child name search as backup option

This should resolve the "No therapy photos" issue and properly display TherapyPhotos for the patient in the clinic patient profile Records tab.