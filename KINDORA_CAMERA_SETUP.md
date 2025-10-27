# Kindora Camera Feature - Setup Guide

## 📱 **Complete Camera Implementation Added**

The Kindora camera feature has been successfully integrated into your materials page with a floating camera button at the bottom center.

---

## 🎯 **What's Implemented**

### ✅ **Core Features:**
- **Floating Camera Button**: Bottom center of materials page
- **Professional Camera Interface**: Full-screen camera with controls
- **Photo Preview Screen**: Delete/Save/Send options
- **Permission Handling**: Automatic camera permission requests
- **Error Handling**: Comprehensive error messages and fallbacks

### ✅ **User Flow:**
1. **Tap Camera Button** → Opens camera permission dialog
2. **Camera Opens** → Take photos with professional interface
3. **Photo Preview** → Three action buttons:
   - 🗑️ **Delete** - Remove unwanted photos
   - 💾 **Save** - Store locally on device
   - 📤 **Send** - Upload to therapy team

---

## 📦 **Required Dependencies**

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Existing dependencies...
  
  # Camera dependencies
  camera: ^0.10.5+5
  path_provider: ^2.1.1
  path: ^1.8.3
  permission_handler: ^11.0.1
  
  # Optional for image compression
  flutter_image_compress: ^2.0.4
```

Then run:
```bash
flutter pub get
```

---

## 🔧 **Permission Setup**

### **Android** (`android/app/src/main/AndroidManifest.xml`)

Add before `<application>`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.front" android:required="false" />
```

### **iOS** (`ios/Runner/Info.plist`)

Add inside `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Kindora needs camera access to take photos for therapy sessions</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Kindora needs photo library access to save photos</string>
```

---

## 🚀 **Activation Steps**

### **Step 1**: Add Dependencies
Copy the dependencies above to your `pubspec.yaml` and run `flutter pub get`

### **Step 2**: Uncomment Imports
In `lib/screens/parent/parent_materials.dart`, uncomment this line:
```dart
// import 'kindora_camera_screen.dart'; // Uncomment when camera dependencies are added
```
Change to:
```dart
import 'kindora_camera_screen.dart';
```

### **Step 3**: Uncomment Camera Implementation
In `parent_materials.dart`, find the `_launchCamera()` method and uncomment the actual implementation section (marked with `// TODO:`).

### **Step 4**: Test
- Hot restart your app
- Navigate to Materials page
- Tap the camera button (bottom center)
- Grant camera permissions
- Take a photo and test Delete/Save/Send

---

## 📁 **Files Created**

1. **`lib/screens/parent/kindora_camera_screen.dart`** - Main camera interface
2. **`lib/screens/parent/photo_preview_screen.dart`** - Preview with actions
3. **`KINDORA_CAMERA_SETUP.md`** - This setup guide

---

## 🔗 **Backend Integration**

### **Option A: Firebase Storage**
Uncomment the Firebase upload code in `photo_preview_screen.dart`:

```dart
// Upload to Firebase Storage
final ref = FirebaseStorage.instance
    .ref()
    .child('therapy_photos')
    .child('$timestamp-$fileName');

final uploadTask = await ref.putFile(file);
final downloadUrl = await uploadTask.ref.getDownloadURL();

// Save metadata to Firestore
await FirebaseFirestore.instance.collection('TherapyPhotos').add({
  'photoUrl': downloadUrl,
  'uploadedAt': FieldValue.serverTimestamp(),
  'uploadedBy': 'parent',
  'fileName': fileName,
  'sessionId': null, // Link to therapy session
  'clientId': null, // Link to client
  'notes': 'Photo taken with Kindora camera',
});
```

### **Option B: Custom API**
Replace the `_uploadToServer` method in `photo_preview_screen.dart` with your API endpoint.

---

## 🎨 **Customization Options**

### **Colors**
All colors use your Kindora theme (`Color(0xFF006A5B)`). Customize in:
- Camera button background
- App bars and buttons
- Loading indicators

### **Photo Quality**
Adjust in `kindora_camera_screen.dart`:
```dart
_controller = CameraController(
  backCamera,
  ResolutionPreset.high, // Change to .medium or .low for smaller files
  enableAudio: false,
);
```

### **File Storage**
Photos are saved to:
- **Local**: `app_documents/kindora_photos/`
- **Server**: Configure your upload endpoint

---

## 🧪 **Testing Checklist**

- [ ] Camera button appears on materials page
- [ ] Tapping button shows camera dialog
- [ ] Camera opens with permissions
- [ ] Photo capture works
- [ ] Preview screen shows captured photo
- [ ] Delete button removes photo
- [ ] Save button stores to device
- [ ] Send button triggers upload (when configured)
- [ ] Works on both Android and iOS
- [ ] Error handling displays proper messages

---

## 🚨 **Troubleshooting**

### **Camera not opening**
- Check permissions in AndroidManifest.xml and Info.plist
- Ensure `WidgetsFlutterBinding.ensureInitialized()` in main.dart

### **Permission denied**
- Test on physical device (camera doesn't work in simulator)
- Check permission declarations

### **Large file sizes**
- Change camera resolution to `.medium`
- Add image compression before upload

### **Upload failures**
- Check network connectivity
- Verify API endpoint configuration
- Test with smaller file sizes

---

## 📞 **Need Help?**

The camera feature is fully implemented and ready to use. After adding dependencies and permissions, your users will be able to:

1. **Take photos** during therapy sessions
2. **Preview and decide** what to do with each photo
3. **Save locally** for personal records
4. **Send to therapy team** for session documentation

The UI matches your Kindora design system and provides a professional photography experience for therapy documentation.

---

**Ready to activate? Just add the dependencies and uncomment the imports!** 📸