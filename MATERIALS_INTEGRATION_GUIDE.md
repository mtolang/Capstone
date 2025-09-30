## Materials Page Integration Guide

### 1. Import the Materials Page

Add this import to your navigation files:

```dart
import 'package:capstone_2/screens/parent/parent_materials.dart';
```

### 2. Add to Navigation Routes

In your route handling (usually in `main.dart` or navigation widget):

```dart
case '/parent_materials':
  return MaterialPageRoute(builder: (context) => const ParentMaterials());
```

### 3. Add to Dashboard Tab Bar

If using the same tab bar as dashboard, update `dashboard_tabbar.dart`:

```dart
// Add materials tab option
TabBar(
  tabs: [
    Tab(text: 'Clinics'),
    Tab(text: 'Materials'),  // Add this
    Tab(text: 'Other'),
  ],
)
```

### 4. Update Parent Navbar

In `parent_navbar.dart`, add materials menu item:

```dart
ListTile(
  leading: Icon(Icons.folder),
  title: Text('Materials'),
  onTap: () {
    Navigator.pushReplacementNamed(context, '/parent_materials');
  },
),
```

### 5. Features Overview

#### Materials Page Features:
- ✅ **Same design as dashboard** (background, tabbar, layout)
- ✅ **Material boxes with 3/4 image, 1/4 title** ratio
- ✅ **Two main sections:**
  - Therapist uploaded materials
  - YouTube developmental therapy videos
- ✅ **Search bar** for filtering content
- ✅ **Category filters** for therapy types
- ✅ **YouTube API integration** for live video fetching

#### Group Calling Features (Already Working):
- ✅ **Up to 4 participants** per call
- ✅ **Add people to ongoing calls** via invite button
- ✅ **Automatic group call conversion** when 3+ people join
- ✅ **Real-time participant management**

### 6. YouTube API Setup

1. Follow `YOUTUBE_API_GUIDE.md` to get your API key
2. Replace `YOUR_YOUTUBE_API_KEY` in `parent_materials.dart`
3. Test with sample data (works without API key)

### 7. Firebase Collections Needed

Create these Firestore collections:

```
TherapyMaterials/
├── {documentId}/
    ├── title: string
    ├── description: string
    ├── category: string
    ├── imageUrl: string
    ├── fileUrl: string
    ├── uploadedBy: string
    └── uploadedAt: timestamp
```

### 8. Testing

```bash
flutter run
# Navigate to Materials page
# Test search functionality
# Test category filters
# Test YouTube video section
```