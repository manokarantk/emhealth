import 'dart:io';
import 'package:flutter/material.dart';
import '../services/firebase_storage_service.dart';
import '../utils/snackbar_helper.dart';

class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final String userId;
  final double size;
  final Function(String imageUrl) onImageUploaded;
  final bool showEditIcon;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    required this.userId,
    this.size = 80,
    required this.onImageUploaded,
    this.showEditIcon = true,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  bool _isUploading = false;

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Choose Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Options
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhotoWithCamera();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    print('🖼️ Gallery option selected');
    
    final imageFile = await FirebaseStorageService.pickImageFromGallery();
    if (imageFile != null) {
      print('✅ Image file received from gallery, proceeding to upload');
      await _uploadImage(imageFile);
    } else {
      print('❌ No image file received from gallery');
      if (mounted) {
        SnackBarHelper.showError(context, 'No image selected from gallery');
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    print('📷 Camera option selected');
    
    final imageFile = await FirebaseStorageService.takePhotoWithCamera();
    if (imageFile != null) {
      print('✅ Image file received from camera, proceeding to upload');
      await _uploadImage(imageFile);
    } else {
      print('❌ No image file received from camera');
      if (mounted) {
        SnackBarHelper.showError(context, 'No photo taken with camera');
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    print('📤 Starting image upload process...');
    setState(() {
      _isUploading = true;
    });

    try {
      print('📤 Uploading image to Firebase Storage...');
      final imageUrl = await FirebaseStorageService.uploadProfileImage(
        imageFile,
        widget.userId,
      );

      if (imageUrl != null) {
        print('✅ Image uploaded successfully: $imageUrl');
        widget.onImageUploaded(imageUrl);
        SnackBarHelper.showSuccess(context, 'Profile image updated successfully!');
      } else {
        print('❌ Image upload failed - no URL returned');
        SnackBarHelper.showError(context, 'Failed to upload image. Please try again.');
      }
    } catch (e) {
      print('❌ Error during image upload: $e');
      SnackBarHelper.showError(context, 'Error uploading image: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _showImagePickerOptions,
      child: Stack(
        children: [
          // Profile Image Container
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : ClipOval(
                    child: widget.currentImageUrl != null
                        ? Image.network(
                            widget.currentImageUrl!,
                            width: widget.size,
                            height: widget.size,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/emhealth.png',
                                width: widget.size,
                                height: widget.size,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/emhealth.png',
                            width: widget.size,
                            height: widget.size,
                            fit: BoxFit.cover,
                          ),
                  ),
          ),
          
          // Edit Icon (if enabled)
          if (widget.showEditIcon && !_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
