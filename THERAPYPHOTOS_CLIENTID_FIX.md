# TherapyPhotos Query Fix - Using clientId Field

## Problem Resolution
Based on the actual TherapyPhotos document structure provided, the issue was using the wrong field for querying. The correct field is `clientId`, not `uploadedById`.

## Updated Query Structure

### TherapyPhotos Document Structure (Actual):
```json
{
  "clientId": "ParAcc02",           // ✅ CORRECT QUERY FIELD
  "uploadedById": "ParAcc02",       // Alternative field
  "category": "progress_photo",     // Photo category
  "photoUrl": "https://...",        // Photo URL
  "fileName": "CAP7411045581068132399.jpg",
  "fileSize": 25358,
  "isActive": true,
  "notes": "Photo taken with Kindora camera app",
  "uploadedBy": "admin",
  "uploaderType": "parent",
  "uploadedAt": Timestamp,
  "tags": ["kindora_camera", "parent_upload", "therapy_progress"]
}
```

### ParentsAcc Document Structure:
```json
Document ID: "ParAcc02"  // ✅ PARENT ID (Document ID)
{
  "Full_Name": "Martin Tols",
  "Email": "mtolang@gmail.com",
  "Contact_Number": "09098766754",
  "Address": "Indangan, Davao City Davao Del Sur",
  // ... other fields
}
```

## Query Changes Made

### 1. Updated Primary Query Field
**Before:**
```dart
.where('uploadedById', isEqualTo: searchParentId)
```

**After:**
```dart
.where('clientId', isEqualTo: searchParentId)
```

### 2. Fallback Query
**Before:**
```dart
.where('childName', isEqualTo: widget.patientName)
```

**After:**
```dart
.where('uploadedById', isEqualTo: searchParentId)  // More reliable fallback
```

### 3. Updated Card Display Fields
**Before:** Used `associatedMaterialTitle` and `associatedMaterialCategory`
**After:** Uses `title` (defaults to "Progress Photo") and `category` (e.g., "progress_photo")

### 4. Removed Unnecessary Filtering
**Before:** Filtered by both `clinicId` and `isActive`
**After:** Only filters by `isActive` since TherapyPhotos doesn't have `clinicId`

## Data Flow Verification

### 1. Patient List → Patient Profile:
```
AcceptedBooking.documentId → widget.patientId (e.g., "ParAcc02")
```

### 2. Parent Info Extraction:
```
_parentId = widget.patientData['originalRequestData']['parentInfo']['parentId'] 
         ?? widget.patientId  // e.g., "ParAcc02"
```

### 3. Info Tab Query (Working):
```dart
FirebaseFirestore.instance
  .collection('ParentsAcc')
  .doc('ParAcc02')  // ✅ Works
```

### 4. Records Tab Query (Fixed):
```dart
FirebaseFirestore.instance
  .collection('TherapyPhotos')
  .where('clientId', isEqualTo: 'ParAcc02')  // ✅ Now works
```

## Expected Result

For parent "ParAcc02", the Records tab should now display:
- ✅ Progress photos uploaded through Kindora camera app
- ✅ Category: "progress_photo" 
- ✅ Notes: "Photo taken with Kindora camera app"
- ✅ Uploaded by: "admin"
- ✅ File info with size and uploader
- ✅ Full-screen photo viewing capability

## Debug Output Enhanced

Console will now show:
```
🔍 Searching TherapyPhotos with clientId: ParAcc02
🔍 TherapyPhoto 0: clientId=ParAcc02, uploadedById=ParAcc02, category=progress_photo, photoUrl=https://...
🔍 Total TherapyPhotos for clientId ParAcc02: [count]
🔍 Filtered records count: [count]
```

## Key Fix Summary

The main issue was **field mismatch**:
- ❌ **Before**: Querying by `uploadedById` or `parentId` 
- ✅ **After**: Querying by `clientId` (the correct field)

This aligns with your TherapyPhotos document structure where `clientId: "ParAcc02"` links the photo to the parent account document ID.

The Records tab should now successfully display therapy photos for the patient.