import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Upload profile image to Firebase Storage
  static Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      print('📤 Starting image upload to Firebase Storage...');
      
      // Create a unique filename
      final fileName = 'profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      print('📁 File path: $fileName');
      
      // Create a reference to the file location
      final storageRef = _storage.ref().child(fileName);
      
      // Upload the file
      print('📤 Uploading file...');
      final uploadTask = storageRef.putFile(imageFile);
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      print('✅ Upload completed');
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔗 Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      return null;
    }
  }

  /// Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      print('🖼️ Attempting to pick image from gallery...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('✅ Image picked from gallery: ${image.path}');
        return File(image.path);
      } else {
        print('❌ No image selected from gallery');
        return null;
      }
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take photo with camera
  static Future<File?> takePhotoWithCamera() async {
    try {
      print('📷 Attempting to take photo with camera...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('✅ Photo taken with camera: ${image.path}');
        return File(image.path);
      } else {
        print('❌ No photo taken with camera');
        return null;
      }
    } catch (e) {
      print('❌ Error taking photo with camera: $e');
      return null;
    }
  }

  /// Delete profile image from Firebase Storage
  static Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isNotEmpty) {
        // Remove the first segment (usually 'v0') and join the rest
        final filePath = pathSegments.skip(1).join('/');
        final storageRef = _storage.ref().child(filePath);
        
        await storageRef.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }

  /// Show image picker options (Gallery or Camera)
  static Future<File?> showImagePickerOptions() async {
    // This method will be called from UI with a bottom sheet
    // For now, we'll default to gallery
    return await pickImageFromGallery();
  }

  /// Upload medical record file to Firebase Storage
  static Future<String> uploadMedicalRecord(String filePath, String storagePath) async {
    try {
      print('📤 Starting medical record upload to Firebase Storage...');
      print('📁 File path: $filePath');
      print('📁 Storage path: $storagePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      // Create a reference to the file location
      final storageRef = _storage.ref().child(storagePath);
      
      // Upload the file
      print('📤 Uploading medical record file...');
      final uploadTask = storageRef.putFile(file);
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      print('✅ Medical record upload completed');
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔗 Medical record download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading medical record: $e');
      throw Exception('Failed to upload medical record: $e');
    }
  }

  /// Upload enquiry images to Firebase Storage
  static Future<List<String>> uploadEnquiryImages(List<String> imagePaths) async {
    try {
      print('📤 Starting enquiry images upload to Firebase Storage...');
      print('📁 Number of images to upload: ${imagePaths.length}');
      
      final List<String> downloadUrls = [];
      
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        print('📤 Uploading image ${i + 1}/${imagePaths.length}: $imagePath');
        
        final file = File(imagePath);
        if (!await file.exists()) {
          print('⚠️ File does not exist, skipping: $imagePath');
          continue;
        }
        
        // Create a unique filename for enquiry images
        final fileName = 'enquiry_images/${DateTime.now().millisecondsSinceEpoch}_${i}_${path.basename(imagePath)}';
        print('📁 Storage path: $fileName');
        
        // Create a reference to the file location
        final storageRef = _storage.ref().child(fileName);
        
        // Upload the file
        final uploadTask = storageRef.putFile(file);
        
        // Wait for the upload to complete
        final snapshot = await uploadTask;
        print('✅ Image ${i + 1} upload completed');
        
        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('🔗 Image ${i + 1} download URL: $downloadUrl');
        
        downloadUrls.add(downloadUrl);
      }
      
      print('✅ All enquiry images uploaded successfully. Total URLs: ${downloadUrls.length}');
      return downloadUrls;
    } catch (e) {
      print('❌ Error uploading enquiry images: $e');
      throw Exception('Failed to upload enquiry images: $e');
    }
  }
}
