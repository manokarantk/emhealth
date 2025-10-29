import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../constants/colors.dart';
import '../widgets/image_upload_widget.dart';
import '../services/api_service.dart';
import '../services/firebase_storage_service.dart';
import 'package:photo_view/photo_view.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedRecordType;
  List<String> _uploadedFilePaths = [];
  
  // API data state
  List<Map<String, dynamic>> medicalRecords = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _limit = 10;
  
  // Filter state
  String? _selectedType;
  String? _searchQuery;
  String _sortBy = 'created_at';
  String _sortOrder = 'DESC';

  @override
  void initState() {
    super.initState();
    print('🚀 MedicalHistoryScreen initState called');
    _loadMedicalRecords();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Load medical records from API
  Future<void> _loadMedicalRecords({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        medicalRecords.clear();
      });
    }

    // Don't return early if this is a refresh or first load
    if (!refresh && _currentPage > 1 && (!_hasMoreData || _isLoading)) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('🔄 Loading medical records - Page: $_currentPage, Limit: $_limit');
      final apiService = ApiService();
      final result = await apiService.getMedicalRecords(
        page: _currentPage,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        type: _selectedType,
        search: _searchQuery,
        context: context,
      );
      print('✅ API Response: $result');

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final records = List<Map<String, dynamic>>.from(data['records'] ?? []);
        final pagination = data['pagination'];
        

        setState(() {
          if (refresh || _currentPage == 1) {
            medicalRecords = records;
          } else {
            medicalRecords.addAll(records);
          }
          
          _hasMoreData = pagination?['has_next'] ?? false;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? 'Failed to load medical records';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error occurred';
        _isLoading = false;
      });
    }
  }

  // Refresh medical records
  Future<void> _refreshRecords() async {
    await _loadMedicalRecords(refresh: true);
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Helper method to get display name for record type
  String _getRecordTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'lab_report':
        return 'Lab Report';
      case 'prescription':
        return 'Prescription';
      case 'test_result':
        return 'Test Result';
      case 'other':
        return 'Other Document';
      default:
        return type.replaceAll('_', ' ').split(' ').map((word) => 
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : ''
        ).join(' ');
    }
  }



  Future<void> _addNewRecord() async {
    // Validate form data
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a record title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRecordType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a record type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      List<String> uploadedFileUrls = [];

      // Upload images to Firebase if any files are selected
      if (_uploadedFilePaths.isNotEmpty) {
        for (String filePath in _uploadedFilePaths) {
          try {
            final downloadUrl = await FirebaseStorageService.uploadMedicalRecord(
              filePath,
              'medical_records/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}',
            );
            uploadedFileUrls.add(downloadUrl);
            print('✅ Image uploaded to Firebase: $downloadUrl');
          } catch (e) {
            print('❌ Error uploading image to Firebase: $e');
            // Continue with other uploads even if one fails
          }
        }
      }

      // Call the API to save the medical record
      final apiService = ApiService();
      final result = await apiService.addMedicalRecord(
        type: _selectedRecordType!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileUrls: uploadedFileUrls,
        context: context,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // Add to local list for immediate display
        final newRecord = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': _titleController.text.trim(),
          'date': DateTime.now().toString().split(' ')[0],
          'type': _selectedRecordType,
          'status': 'Uploaded',
          'description': _descriptionController.text.trim(),
          'fileSize': uploadedFileUrls.isNotEmpty ? '${uploadedFileUrls.length} files' : 'No files',
          'recordType': 'uploaded',
          'uploadedBy': 'User',
          'canDelete': true,
          'filePaths': uploadedFileUrls,
        };

        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        _selectedRecordType = null;
        _uploadedFilePaths.clear();

        Navigator.of(context).pop(); // Close bottom sheet
        
        // Refresh the medical records list
        await _refreshRecords();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Medical record added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add medical record'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();
      
      print('❌ Error in _addNewRecord: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddRecordBottomSheet() {
    // Dismiss keyboard before showing bottom sheet
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        // Use a fixed height that doesn't change when keyboard appears
        final maxHeight = (screenHeight * 0.85).clamp(500.0, screenHeight * 0.85);
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: maxHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Medical Record',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    // Form content
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Record Title',
                              prefixIcon: const Icon(Icons.description, color: AppColors.primaryBlue),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.notes, color: AppColors.primaryBlue),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedRecordType,
                            decoration: InputDecoration(
                              labelText: 'Record Type',
                              prefixIcon: const Icon(Icons.category, color: AppColors.primaryBlue),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.grey, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'lab_report', child: Text('Lab Report')),
                              DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                              DropdownMenuItem(value: 'test_result', child: Text('Test Result')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                _selectedRecordType = value;
                              });
                            },
                          ),
                                                     const SizedBox(height: 20),
                           ImageUploadWidget(
                             title: 'Upload Medical Record',
                             subtitle: 'Upload clear images and PDFs of your medical reports (optional)',
                             uploadButtonText: 'Upload Files',
                             maxSizeText: 'Max 10MB',
                             allowPdfUpload: true,
                             initialImages: _uploadedFilePaths,
                             onImagesChanged: (List<String> images) {
                               setModalState(() {
                                 _uploadedFilePaths = images;
                               });
                             },
                           ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Bottom buttons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppColors.primaryBlue),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: AppColors.primaryBlue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _addNewRecord();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Save Record'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditRecordBottomSheet(Map<String, dynamic> record) {
    // Pre-fill the form with existing record data
    _titleController.text = record['title'] ?? '';
    _descriptionController.text = record['description'] ?? '';
    _selectedRecordType = record['type'] ?? 'other';
    _uploadedFilePaths = List<String>.from(record['file_urls'] ?? []);

    // Dismiss keyboard before showing bottom sheet
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        // Use a fixed height that doesn't change when keyboard appears
        final maxHeight = (screenHeight * 0.85).clamp(500.0, screenHeight * 0.85);
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: maxHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Edit Medical Record',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // Title field
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.edit),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Description field
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Type field
                          DropdownButtonFormField<String>(
                            value: _selectedRecordType,
                            decoration: const InputDecoration(
                              labelText: 'Record Type *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                              contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'lab_report', child: Text('Lab Report')),
                              DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                              DropdownMenuItem(value: 'test_result', child: Text('Test Result')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                _selectedRecordType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Image upload widget
                          ImageUploadWidget(
                            title: 'Update Medical Record Files',
                            subtitle: 'Upload new images and PDFs or keep existing ones (optional)',
                            uploadButtonText: 'Upload New Files',
                            maxSizeText: 'Max 10MB',
                            allowPdfUpload: true,
                            initialImages: _uploadedFilePaths,
                            onImagesChanged: (List<String> images) {
                              setModalState(() {
                                _uploadedFilePaths = images;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.primaryBlue),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.primaryBlue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _updateRecord(record);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Update Record'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateRecord(Map<String, dynamic> record) async {
    // Validate form data
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a record title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRecordType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a record type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Upload new images to Firebase if any new files are selected
      List<String> finalFileUrls = [];
      
      // Keep existing files that haven't been removed
      final existingFiles = record['file_urls'] ?? [];
      final existingFilePaths = List<String>.from(existingFiles);
      
      // Add new uploaded files
      for (String filePath in _uploadedFilePaths) {
        if (!existingFilePaths.contains(filePath)) {
          // This is a new file, upload it to Firebase
          try {
            final downloadUrl = await FirebaseStorageService.uploadMedicalRecord(
              filePath,
              'medical_records/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}',
            );
            finalFileUrls.add(downloadUrl);
            print('✅ New file uploaded to Firebase: $downloadUrl');
          } catch (e) {
            print('❌ Error uploading new file to Firebase: $e');
            // Continue with other uploads even if one fails
          }
        } else {
          // This is an existing file, keep the URL
          finalFileUrls.add(filePath);
        }
      }

      // Call the API to update the medical record
      final apiService = ApiService();
      print('🔍 Record ID type: ${record['id'].runtimeType}, value: ${record['id']}');
      final result = await apiService.updateMedicalRecord(
        recordId: record['id'].toString(), // Ensure it's a string
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileUrls: finalFileUrls,
        context: context,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // Update the local record for immediate display
        final updatedRecord = {
          ...record,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _selectedRecordType,
          'file_urls': finalFileUrls,
          'updated_at': DateTime.now().toIso8601String(),
        };

        setState(() {
          final index = medicalRecords.indexWhere((r) => r['id'] == record['id']);
          if (index != -1) {
            medicalRecords[index] = updatedRecord;
          }
        });

        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        _selectedRecordType = null;
        _uploadedFilePaths.clear();

        Navigator.of(context).pop(); // Close bottom sheet
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Medical record updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update medical record'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();
      
      print('❌ Error in _updateRecord: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: const Text(
          'Medical History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddRecordBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRecords,
        child: _isLoading && medicalRecords.isEmpty
            ? _buildLoadingState()
            : _hasError
                ? _buildErrorState()
                : medicalRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildRecordsList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading medical records...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshRecords,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicalRecords.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == medicalRecords.length) {
          // Show loading indicator for pagination
          if (_isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        
        final record = medicalRecords[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    // Handle API data structure
    final String type = record['type'] ?? '';
    final String title = record['title'] ?? '';
    final String description = record['description'] ?? '';
    final String uploadedBy = record['uploaded_by'] ?? 'user';
    final List<dynamic> fileUrls = record['file_urls'] ?? [];
    final String createdAt = record['created_at'] ?? '';
    final Map<String, dynamic>? familyMember = record['family_member'];
    final Map<String, dynamic>? appointment = record['appointment'];
    
    // Determine if it's a booking record (has appointment data)
    final bool isBookingRecord = appointment != null;
    final bool canDelete = uploadedBy == 'user' && !isBookingRecord; // Only user-uploaded records that are not from booking can be deleted
    
    // Format date
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
      } catch (e) {
        formattedDate = createdAt;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBookingRecord 
              ? AppColors.primaryBlue.withOpacity(0.3)
              : Colors.grey[200]!,
          width: isBookingRecord ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type indicator
            Row(
              children: [
                // Type indicator icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isBookingRecord 
                        ? AppColors.primaryBlue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isBookingRecord ? Icons.local_hospital : Icons.upload_file,
                    size: 20,
                    color: isBookingRecord ? AppColors.primaryBlue : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBookingRecord 
                            ? '${_getRecordTypeDisplayName(type)} • ${appointment?['organization']?['name'] ?? 'Unknown Lab'}'
                            : '${_getRecordTypeDisplayName(type)} • ${uploadedBy == 'user' ? 'Uploaded by You' : 'Uploaded by ${uploadedBy}'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options button
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('View'),
                        ],
                      ),
                    ),
                    if (canDelete) // Only user-uploaded records can be edited
                    const PopupMenuItem(
                        value: 'edit',
                      child: Row(
                        children: [
                            Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                            Text('Edit'),
                        ],
                      ),
                    ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    _handleRecordAction(value, record);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
            
            // Family member information
            if (familyMember != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${familyMember['name'] ?? 'Unknown'} (${familyMember['relationship'] ?? 'Family Member'})',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // File information
            if (fileUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${fileUrls.length} file${fileUrls.length != 1 ? 's' : ''} attached',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Footer with status, date, and file size
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(isBookingRecord ? 'Completed' : 'Uploaded').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isBookingRecord ? 'Completed' : 'Uploaded',
                    style: TextStyle(
                      color: _getStatusColor(isBookingRecord ? 'Completed' : 'Uploaded'),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${fileUrls.length} file${fileUrls.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Booking ID for booking records
            if (isBookingRecord && appointment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Booking ID: ${appointment['alias'] ?? 'N/A'}',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No Medical Records',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first medical record to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddRecordBottomSheet,
            icon: const Icon(Icons.add),
            label: const Text('Add First Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRecordAction(String action, Map<String, dynamic> record) {
    switch (action) {
      case 'view':
        _viewRecord(record);
        break;
      case 'edit':
        _editRecord(record);
        break;
      case 'delete':
        _deleteRecord(record);
        break;
    }
  }

  void _viewRecord(Map<String, dynamic> record) {
    _showViewRecordBottomSheet(record);
  }

  void _showViewRecordBottomSheet(Map<String, dynamic> record) {
    // Extract record data
    final String type = record['type'] ?? '';
    final String title = record['title'] ?? '';
    final String description = record['description'] ?? '';
    final String uploadedBy = record['uploaded_by'] ?? 'user';
    final List<dynamic> fileUrls = record['file_urls'] ?? [];
    final String createdAt = record['created_at'] ?? '';
    final String updatedAt = record['updated_at'] ?? '';
    final Map<String, dynamic>? familyMember = record['family_member'];
    final Map<String, dynamic>? appointment = record['appointment'];
    
    // Determine if it's a booking record
    final bool isBookingRecord = appointment != null;
    
    // Format dates
    String formattedCreatedDate = '';
    String formattedUpdatedDate = '';
    
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        formattedCreatedDate = '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedCreatedDate = createdAt;
      }
    }
    
    if (updatedAt.isNotEmpty && updatedAt != createdAt) {
      try {
        final date = DateTime.parse(updatedAt);
        formattedUpdatedDate = '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedUpdatedDate = updatedAt;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRecordTypeDisplayName(type),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Record Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isBookingRecord 
                              ? AppColors.primaryBlue.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isBookingRecord ? AppColors.primaryBlue : Colors.green,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBookingRecord ? Icons.local_hospital : Icons.upload_file,
                              size: 16,
                              color: isBookingRecord ? AppColors.primaryBlue : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isBookingRecord ? 'Booking Record' : 'Uploaded Record',
                              style: TextStyle(
                                color: isBookingRecord ? AppColors.primaryBlue : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description Section
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Family Member Information
                      if (familyMember != null) ...[
                        const Text(
                          'Family Member',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.family_restroom,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      familyMember['name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    Text(
                                      'Relationship: ${familyMember['relationship'] ?? 'Family Member'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Appointment Information
                      if (isBookingRecord) ...[
                        const Text(
                          'Appointment Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_hospital,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      appointment['organization']['name'] ?? 'Unknown Lab',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.confirmation_number,
                                    color: AppColors.primaryBlue,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Booking ID: ${appointment['alias'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (appointment['datetime'] != null && appointment['datetime'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: AppColors.primaryBlue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Date: ${_formatAppointmentDate(appointment['datetime'])}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Files Section
                      if (fileUrls.isNotEmpty) ...[
                        const Text(
                          'Attached Files',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...fileUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final fileUrl = entry.value.toString();
                          final isImage = _isImageFile(fileUrl);
                          final isPDF = _isPDFFile(fileUrl);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                // File icon or image preview
                                if (isImage)
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        fileUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.image,
                                            color: Colors.grey[600],
                                            size: 20,
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    isPDF ? Icons.picture_as_pdf : Icons.insert_drive_file,
                                    color: isPDF ? Colors.red[600] : Colors.grey[600],
                                    size: 20,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isImage ? 'Image ${index + 1}' : 
                                    isPDF ? 'PDF Document ${index + 1}' : 'File ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (isImage) {
                                      _viewImage(fileUrl, 'Image ${index + 1}');
                                    } else if (isPDF) {
                                      _openPDFDirectly(fileUrl, 'PDF Document ${index + 1}');
                                    } else {
                                      // For other file types, show a message
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('File type not supported for viewing: ${index + 1}'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    isImage ? Icons.visibility : 
                                    isPDF ? Icons.visibility : Icons.open_in_new,
                                    color: isPDF ? Colors.blue[600] : Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                      
                      // Upload Information
                      const Text(
                        'Record Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Uploaded by', uploadedBy == 'user' ? 'You' : uploadedBy),
                            _buildInfoRow('Created on', formattedCreatedDate),
                            if (formattedUpdatedDate.isNotEmpty)
                              _buildInfoRow('Last updated', formattedUpdatedDate),
                            _buildInfoRow('Record type', _getRecordTypeDisplayName(type)),
                            _buildInfoRow('Status', isBookingRecord ? 'Completed' : 'Uploaded'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Bottom button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAppointmentDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  bool _isImageFile(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  bool _isPDFFile(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.pdf');
  }

  void _viewImage(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // PhotoView with zoom functionality
              PhotoView(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                loadingBuilder: (context, event) => Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: event == null ? null : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                      color: Colors.white,
                    ),
                  ),
                ),
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Top buttons (Close and Download)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Download button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: () => _downloadImage(imageUrl, title),
                        icon: const Icon(Icons.download, color: Colors.white, size: 24),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                    // Close button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Zoom instructions (appears briefly)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pinch to zoom • Drag to pan • Tap to close',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPDFDirectly(String pdfUrl, String title) async {
    try {
      final Uri url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open PDF: $title'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadImage(String imageUrl, String title) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download images'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Get the downloads directory
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        // Create filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = imageUrl.split('.').last.split('?').first;
        final filename = '${title.replaceAll(' ', '_')}_$timestamp.$extension';
        final file = File('${downloadsDir.path}/$filename');

        // Write the file
        await file.writeAsBytes(response.bodyBytes);

        // Hide loading indicator
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to Downloads: $filename'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Hide loading indicator
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download image: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if it's still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editRecord(Map<String, dynamic> record) {
    _showEditRecordBottomSheet(record);
  }

  void _deleteRecord(Map<String, dynamic> record) {
    // Determine if record can be deleted using the same logic as in _buildRecordCard
    final String uploadedBy = record['uploaded_by'] ?? 'user';
    final Map<String, dynamic>? appointment = record['appointment'];
    final bool isBookingRecord = appointment != null;
    final bool canDelete = uploadedBy == 'user' && !isBookingRecord;
    
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This record cannot be deleted as it is from a booking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Record'),
          content: Text('Are you sure you want to delete "${record['title']}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmDeleteRecord(record);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteRecord(Map<String, dynamic> record) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final apiService = ApiService();
      final result = await apiService.deleteMedicalRecord(
        recordId: record['id']?.toString() ?? '',
        context: context,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (result['success']) {
        // Remove from local list
        setState(() {
          medicalRecords.removeWhere((r) => r['id'] == record['id']);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${record['title']} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message from API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete record'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Pending':
        return Colors.red;
      case 'Uploaded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 