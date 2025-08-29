# Firebase Storage Setup for Profile Image Upload

This document explains how to set up Firebase Storage for the profile image upload feature in the EmHealth Flutter app.

## Prerequisites

1. Firebase project already configured in your app
2. Firebase Core dependency already added
3. Firebase Storage dependency added to `pubspec.yaml`
4. Image picker dependency added to `pubspec.yaml`
5. Path dependency added to `pubspec.yaml`
6. Firebase initialization properly configured in `main.dart`

## Setup Steps

### 1. Firebase Initialization

Ensure Firebase is properly initialized in your `main.dart` file:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### 2. Firebase Console Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Storage** in the left sidebar
4. Click **Get Started** if Storage is not enabled
5. Choose a location for your Storage bucket (recommend: same region as your app)
6. Start in **test mode** for development (you can change security rules later)

### 2. Security Rules

Update your Firebase Storage security rules to allow authenticated users to upload profile images:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload profile images
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default rule - deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. Android Configuration

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/` directory
3. Ensure your `android/app/build.gradle` has the Google Services plugin:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // Add this line
}
```

4. **Permissions are already added** to `android/app/src/main/AndroidManifest.xml`:
   - Camera permission
   - Storage permissions
   - Photo library permissions

### 4. iOS Configuration

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to your iOS project using Xcode
3. Ensure it's included in your app bundle
4. **Permissions are already added** to `ios/Runner/Info.plist`:
   - Camera usage description
   - Photo library usage description

### 5. Web Configuration (if applicable)

1. Add Firebase configuration to `web/index.html`:

```html
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-storage.js"></script>
```

## Features Implemented

### 1. Profile Image Upload Service (`lib/services/firebase_storage_service.dart`)

- **Upload Profile Image**: Uploads images to Firebase Storage with unique filenames
- **Pick from Gallery**: Allows users to select images from their device gallery
- **Take Photo**: Allows users to take photos using the device camera
- **Delete Image**: Removes images from Firebase Storage
- **Error Handling**: Comprehensive error handling for all operations

### 2. Profile Image Picker Widget (`lib/widgets/profile_image_picker.dart`)

- **Reusable Component**: Can be used anywhere in the app
- **Bottom Sheet UI**: Modern UI with gallery/camera options
- **Loading States**: Shows loading indicators during upload
- **Error Handling**: Displays error messages using SnackBar
- **Customizable**: Configurable size and edit icon visibility

### 3. API Integration

- **Update Profile API**: New API method to update profile image URL
- **Backend Sync**: Sends Firebase Storage URL to your backend
- **Profile Refresh**: Automatically refreshes profile data after upload

## Usage

### In Profile Screen

```dart
ProfileImagePicker(
  currentImageUrl: userProfile?['profile']?['profileimage'],
  userId: userProfile?['user']?['id']?.toString() ?? 'unknown',
  size: 80,
  onImageUploaded: _updateProfileImage,
  showEditIcon: true,
)
```

### In Header

```dart
ProfileImagePicker(
  currentImageUrl: userProfile?['profileimage'],
  userId: userProfile?['user']?['id']?.toString() ?? 'unknown',
  size: 40,
  onImageUploaded: _updateProfileImage,
  showEditIcon: false, // Don't show edit icon in header
)
```

## File Structure

```
lib/
├── services/
│   └── firebase_storage_service.dart    # Firebase Storage operations
├── widgets/
│   └── profile_image_picker.dart        # Reusable image picker widget
└── screens/
    └── landing_page.dart                # Updated with profile image picker
```

## Security Considerations

1. **Authentication Required**: Only authenticated users can upload images
2. **User Isolation**: Users can only upload to their own folder
3. **File Size Limits**: Images are compressed to 1024x1024 max
4. **File Type Validation**: Only image files are accepted
5. **Unique Filenames**: Prevents filename conflicts

## Error Handling

The implementation includes comprehensive error handling:

- Network connectivity issues
- Firebase Storage errors
- Image picker permission denials
- File size/format issues
- Backend API errors

## Performance Optimizations

1. **Image Compression**: Images are compressed to 85% quality
2. **Size Limits**: Maximum dimensions of 1024x1024 pixels
3. **Caching**: Firebase Storage handles caching automatically
4. **Lazy Loading**: Images load only when needed

## Testing

To test the feature:

1. Run the app on a device (not emulator for camera functionality)
2. Navigate to the Profile tab
3. Tap on the profile image
4. Choose "Gallery" or "Camera"
5. Select/take an image
6. Verify the image uploads and displays correctly

## Troubleshooting

### Common Issues

1. **Gallery/Camera Not Working**: 
   - Ensure permissions are granted at runtime
   - Check console logs for permission status
   - Verify manifest/Info.plist permissions are correct

2. **Permission Denied**: 
   - App will automatically request permissions
   - If permanently denied, guide user to settings
   - Check console logs for detailed permission status

3. **Upload Fails**: 
   - Check Firebase Storage rules and network connectivity
   - Verify Firebase project configuration
   - Check console logs for upload errors

4. **Image Not Displaying**: 
   - Verify the Firebase Storage URL is accessible
   - Check network connectivity
   - Verify image format is supported

5. **Build Errors**: 
   - Ensure all dependencies are properly installed
   - Run `flutter clean` and `flutter pub get`
   - Check for version conflicts

### Debug Steps

1. **Check Permissions**: Use the debug logs to see permission status
2. **Check Firebase Console**: Verify Storage rules and project setup
3. **Verify Configuration**: Ensure `google-services.json` is in correct location
4. **Network Check**: Verify internet connectivity
5. **Console Logs**: Review detailed logs for specific error messages
6. **Test Permissions**: Use the permission checker method

### Debug Commands

```dart
// Check image picker status
final imageFile = await FirebaseStorageService.pickImageFromGallery();
if (imageFile != null) {
  print('Image picked successfully: ${imageFile.path}');
} else {
  print('No image selected or permission denied');
}
```

### Common Issues

- **Firebase Not Initialized**: Ensure Firebase is properly initialized in `main.dart` with correct options
- **Gallery/Camera Not Working**: Check if the device has photos/camera available
- **Permission Denied**: The app will automatically request permissions when needed
- **Upload Fails**: Check Firebase Storage rules and network connectivity

## Future Enhancements

1. **Image Cropping**: Add image cropping functionality
2. **Multiple Formats**: Support for more image formats
3. **Batch Upload**: Upload multiple images at once
4. **Image Filters**: Add basic image editing features
5. **Cloud Functions**: Process images on the server side
