import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../constants/colors.dart';

class ImageUploadWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String uploadButtonText;
  final String maxSizeText;
  final Function(List<String>) onImagesChanged;
  final List<String> initialImages;
  final bool allowPdfUpload;

  const ImageUploadWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.uploadButtonText,
    required this.maxSizeText,
    required this.onImagesChanged,
    this.initialImages = const [],
    this.allowPdfUpload = false,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  List<String> _uploadedImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadedImages = List<String>.from(widget.initialImages);
  }

  void _pickImage() async {
    // Show image source selection dialog
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
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
              Text(
                widget.allowPdfUpload ? 'Select File Source' : 'Select Image Source',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Gallery option
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from your existing photos'),
                onTap: () {
                  print('🖼️ Gallery option selected');
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              
              // Camera option
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo with camera'),
                onTap: () {
                  print('🖼️ Camera option selected');
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              
              // PDF option (only if PDF upload is enabled)
              if (widget.allowPdfUpload) ...[
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppColors.primaryBlue),
                  title: const Text('PDF Document'),
                  subtitle: const Text('Upload PDF file'),
                  onTap: () {
                    print('📄 PDF option selected');
                    Navigator.of(context).pop();
                    _pickPdfFile();
                  },
                ),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _pickImageFromSource(ImageSource source) async {
    try {
      print('🖼️ Starting image picker with source: $source');
      
      setState(() {
        _isUploading = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      print('🖼️ Image picker result: ${image?.path ?? "null"}');

      if (image != null && mounted) {
        print('🖼️ Image selected successfully: ${image.path}');
        setState(() {
          _uploadedImages.add(image.path);
          _isUploading = false;
        });
        
        // Notify parent widget
        widget.onImagesChanged(_uploadedImages);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} uploaded successfully! (${_uploadedImages.length} images)'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        print('🖼️ No image selected or user cancelled');
        setState(() {
          _isUploading = false;
        });
        
        // Show a gentle message that no image was selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No image selected. You can try again or continue without uploading.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('🖼️ Error in image picker: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pickPdfFile() async {
    try {
      print('📄 Starting PDF file picker...');
      
      setState(() {
        _isUploading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      print('📄 PDF picker result: ${result?.files.first.path ?? "null"}');

      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        print('📄 PDF selected successfully: ${file.path}');
        
        setState(() {
          _uploadedImages.add(file.path!);
          _isUploading = false;
        });
        
        // Notify parent widget
        widget.onImagesChanged(_uploadedImages);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF document uploaded successfully! (${_uploadedImages.length} files)'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        print('📄 No PDF selected or user cancelled');
        setState(() {
          _isUploading = false;
        });
        
        // Show a gentle message that no PDF was selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No PDF selected. You can try again or continue without uploading.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('📄 Error in PDF picker: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
    // Notify parent widget
    widget.onImagesChanged(_uploadedImages);
  }

  void _clearAllImages() {
    setState(() {
      _uploadedImages.clear();
    });
    // Notify parent widget
    widget.onImagesChanged(_uploadedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and subtitle
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        
        // Upload area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: _isUploading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _uploadedImages.isNotEmpty
                  ? Column(
                      children: [
                        // Images grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _uploadedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _isPdfFile(_uploadedImages[index])
                                        ? Container(
                                            color: Colors.red[50],
                                            child: const Center(
                                              child: Icon(
                                                Icons.picture_as_pdf,
                                                size: 32,
                                                color: Colors.red,
                                              ),
                                            ),
                                          )
                                        : Image.file(
                                            File(_uploadedImages[index]),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[100],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 24,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_uploadedImages.length} Image${_uploadedImages.length > 1 ? 's' : ''} Selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.edit),
                              label: const Text('Add More'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _clearAllImages,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Remove All', style: TextStyle(color: Colors.red)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 48,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.uploadButtonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.allowPdfUpload 
                              ? 'Camera, Gallery or PDF • JPG, PNG, PDF (${widget.maxSizeText}) • Multiple files allowed'
                              : 'Camera or Gallery • JPG, PNG (${widget.maxSizeText}) • Multiple images allowed',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file, color: AppColors.primaryBlue),
                          label: Text(
                            widget.allowPdfUpload ? 'Select File' : 'Select Image', 
                            style: const TextStyle(color: AppColors.primaryBlue)
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
