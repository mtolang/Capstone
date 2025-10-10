# Therapist Navigation Bar Usage Guide

## Overview
The `TherapistNavbar` is a reusable navigation drawer component that can be used across all therapist pages for consistent navigation experience.

## Features
- ✅ **Reusable across all therapist pages**
- ✅ **Highlights current page**
- ✅ **Consistent styling and branding**
- ✅ **Smart navigation with fallbacks**
- ✅ **Logout confirmation dialog**
- ✅ **Error handling for missing routes**

## How to Use

### 1. Import the Navbar
```dart
import 'package:capstone_2/screens/therapist/ther_navbar.dart';
```

### 2. Add to Any Page
```dart
class YourTherapistPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Page Title'),
        backgroundColor: const Color(0xFF006A5B),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      
      // Add the reusable navbar here
      drawer: const TherapistNavbar(currentPage: 'your_page_key'),
      
      body: YourPageContent(),
    );
  }
}
```

### 3. Current Page Keys
Use these keys to highlight the current page:

- `'profile'` - Profile page
- `'booking'` - Booking page  
- `'materials'` - Materials page
- `'patients'` - Patient List page
- `'staff'` - Clinic Staff page
- `'chat'` - Chat page

## Example Pages Created

### 1. Therapist Booking Page
- **File**: `lib/screens/therapist/ther_booking_page.dart`
- **Route**: `/therapistbooking`
- **Uses**: TherBookingTabbar component

### 2. Therapist Materials Page  
- **File**: `lib/screens/therapist/ther_materials_page.dart`
- **Route**: `/therapistmaterials`
- **Template**: Basic page with placeholder content

## Navigation Features

### Smart Navigation
- Closes drawer automatically when navigating
- Prevents navigation to current page
- Shows "coming soon" message for unimplemented routes

### Visual Feedback
- Current page is highlighted with background color
- Current page shows arrow indicator
- Consistent icon and text styling

### Logout Process
- Shows confirmation dialog
- Displays loading indicator
- Proper error handling
- Clears all user session data

## Available Routes

The navbar automatically handles these routes:

```dart
'/therapistprofile'    // Profile page
'/therapistbooking'    // Booking page (new)
'/therapistmaterials'  // Materials page (new)
'/therapistpatients'   // Patient List (placeholder)
'/therapiststaff'      // Clinic Staff (placeholder)
'/therapistchat'       // Chat (placeholder)
```

## Benefits

1. **Consistency**: Same navigation experience across all pages
2. **Maintainability**: Update navbar once, applies everywhere
3. **User Experience**: Clear visual feedback for current page
4. **Error Prevention**: Graceful handling of missing routes
5. **Code Reuse**: No duplicate navigation code

## Future Enhancements

You can easily extend the navbar by:
- Adding new navigation items
- Implementing additional pages
- Adding role-based navigation
- Including user info in header
- Adding notification badges

## Usage in Existing Pages

### Before (Old Method)
```dart
// Had to copy entire drawer code in every page
drawer: Drawer(
  child: ListView(
    children: [
      // 50+ lines of repeated code
    ],
  ),
),
```

### After (New Method)
```dart
// Simple one-liner
drawer: const TherapistNavbar(currentPage: 'profile'),
```

This reduces code duplication and makes maintenance much easier!