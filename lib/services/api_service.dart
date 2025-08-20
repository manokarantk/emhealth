import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../constants/api_config.dart';
import '../utils/auth_utils.dart';
import 'token_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Headers for API requests
  Future<Map<String, String>> get _headers async {
    final token = await TokenService.getToken();
    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Handle API response and check for token expiration
  Map<String, dynamic> _handleResponse(http.Response response, BuildContext? context) {
    final responseData = jsonDecode(response.body);
    
    // Check for token expiration
    if (response.statusCode == 401 || AuthUtils.isTokenExpiredResponse(responseData)) {
      if (context != null) {
        AuthUtils.handleTokenExpiration(context);
      }
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
        'error': 'TOKEN_EXPIRED',
      };
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': responseData['data'],
        'message': responseData['message'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Request failed',
        'error': responseData['error'] ?? 'Unknown error',
      };
    }
  }

  // Request OTP API
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requestOtp}'),
        headers: headers,
        body: jsonEncode({
          'phone': phone,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send OTP',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Verify OTP API
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyOtp}'),
        headers: headers,
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to verify OTP',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get user profile API
  Future<Map<String, dynamic>> getUserProfile(BuildContext? context) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
        headers: headers,
      );

      return _handleResponse(response, context);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get mobile user profile API
  Future<Map<String, dynamic>> getMobileProfile(BuildContext? context) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mobileProfile}'),
        headers: headers,
      );

      return _handleResponse(response, context);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get banners API
  Future<Map<String, dynamic>> getBanners({
    int page = 1,
    int limit = 10,
    bool isActive = true,
    String userSegment = 'all_users',
    String displayType = 'banner',
    String targetPage = '/home',
    String search = 'health',
    String sortBy = 'priority',
    String sortOrder = 'ASC',
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.banners}'),
        headers: headers,
        body: jsonEncode({
          'page': page,
          'limit': limit,
          'is_active': isActive,
          'user_segment': userSegment,
          'display_type': displayType,
          'target_page': targetPage,
          'search': search,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get banners',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get top diagnosis tests API
  Future<Map<String, dynamic>> getTopTests() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.topTests}'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get top tests',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get top packages API
  Future<Map<String, dynamic>> getTopPackages() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.topPackages}'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get top packages',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Add money to wallet API
  Future<Map<String, dynamic>> addMoneyToWallet({
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    try {
      print('🔄 API Service: Making add money to wallet API call to ${ApiConfig.baseUrl}${ApiConfig.addMoneyToWallet}');
      print('🔄 API Service: Request body: {"amount": $amount, "payment_method": "$paymentMethod", "description": "$description"}');

      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addMoneyToWallet}'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'payment_method': paymentMethod,
          if (description != null) 'description': description,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('🔄 API Service: Request timeout for add money to wallet API');
          throw Exception('Request timeout');
        },
      );

      print('🔄 API Service: Response status code: ${response.statusCode}');
      print('🔄 API Service: Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add money to wallet',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get mobile wallet API
  Future<Map<String, dynamic>> getMobileWallet({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('🔄 API Service: Making mobile wallet API call to ${ApiConfig.baseUrl}${ApiConfig.mobileWallet}');
      print('🔄 API Service: Request parameters: page=$page, limit=$limit');

      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mobileWallet}?page=$page&limit=$limit'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔄 API Service: Request timeout for mobile wallet API');
          throw Exception('Request timeout');
        },
      );

      print('🔄 API Service: Response status code: ${response.statusCode}');
      print('🔄 API Service: Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get wallet information',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get appointment history API
  Future<Map<String, dynamic>> getAppointmentHistory({
    required String bookingType, // 'past' or 'future'
    int page = 1,
    int limit = 10,
    int statusId = 1,
    int paymentStatus = 1,
  }) async {
    try {
      print('🔄 API Service: Making appointment history API call to ${ApiConfig.baseUrl}${ApiConfig.appointmentHistory}');
      print('🔄 API Service: Request body: {"booking_type": "$bookingType", "page": $page, "limit": $limit, "status_id": $statusId, "payment_status": $paymentStatus}');

      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointmentHistory}'),
        headers: headers,
        body: jsonEncode({
          'booking_type': bookingType,
          'page': page,
          'limit': limit,
          'status_id': statusId,
          'payment_status': paymentStatus,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔄 API Service: Request timeout for appointment history API');
          throw Exception('Request timeout');
        },
      );

      print('🔄 API Service: Response status code: ${response.statusCode}');
      print('🔄 API Service: Response body history: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          
          'success': false,
          'message': responseData['message'] ?? 'Failed to get appointment history',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get package organizations API
  Future<Map<String, dynamic>> getPackageOrganizations({
    required String packageId,
    List<String> packageIds = const [],
    List<String> testIds = const [],
  }) async {
    try {
      print('🔄 API Service: Making package organizations API call to ${ApiConfig.baseUrl}${ApiConfig.packageOrganizations}');
      print('🔄 API Service: Request body: {"package_ids": $packageIds, "packageId": "$packageId", "test_ids": $testIds}');

      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.packageOrganizations}'),
        headers: headers,
        body: jsonEncode({
          'package_ids': packageIds.isNotEmpty ? packageIds : [packageId],
          'packageId': packageId,
          'test_ids': testIds,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔄 API Service: Request timeout for package organizations API');
          throw Exception('Request timeout');
        },
      );

      print('🔄 API Service: Response status code: ${response.statusCode}');
      print('🔄 API Service: Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get package organizations',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get packages API (new endpoint)
  Future<Map<String, dynamic>> getPackages({
    int page = 1,
    int limit = 10,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    String? search,
    String? category,
    String? organizationId,
  }) async {
    try {
      print('🔄 API Service: Making packages API call to ${ApiConfig.baseUrl}${ApiConfig.mobilePackages}');
      
      final requestBody = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      
      // Add search parameter if provided
      print('🔍 Before adding search - search value: "$search"');
      if (search != null && search.isNotEmpty) {
        requestBody['search'] = search;
        print('🔍 Search parameter added to packages request body');
      } else {
        print('🔍 Search parameter NOT added to packages request body');
      }
      
      // Add category parameter if provided
      if (category != null && category.isNotEmpty) {
        requestBody['category'] = category;
        print('🏷️ Category parameter added to packages request body: $category');
      }
      
      // Add organization ID parameter if provided
      if (organizationId != null && organizationId.isNotEmpty) {
        requestBody['organization_id'] = organizationId;
        print('🏥 Organization ID parameter added to packages request body: $organizationId');
      }
      
      print('🔄 API Service: Request body: ${jsonEncode(requestBody)}');
      
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mobilePackages}'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('🔄 API Service: Request timeout for packages API');
          throw Exception('Request timeout');
        },
      );

      print('🔄 API Service: Response status code: ${response.statusCode}');
      print('🔄 API Service: Response body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get packages',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get diagnosis tests API
  Future<Map<String, dynamic>> getDiagnosisTests({
    int page = 1,
    int limit = 10,
    double latitude = 12.95154427492096,
    double longitude = 80.25149535327924,
    String? search,
    String? category,
    String? organizationId,
  }) async {
    try {
      final headers = await _headers;
      final requestBody = <String, dynamic>{
        'page': page,
        'limit': limit,
        'latitude': latitude,
        'longitude': longitude,
      };
      
      // Add search parameter if provided
      print('🔍 Before adding search - search value: "$search"');
      print('🔍 Search is null: ${search == null}');
      print('🔍 Search is empty: ${search?.isEmpty ?? true}');
      
      if (search != null && search.isNotEmpty) {
        requestBody['search'] = search;
        print('🔍 Search parameter added to request body');
      } else {
        print('🔍 Search parameter NOT added to request body');
      }
      
      // Add category parameter if provided
      if (category != null && category.isNotEmpty) {
        requestBody['category'] = category;
        print('🏷️ Category parameter added to request body: $category');
      }
      
      // Add organization ID parameter if provided
      if (organizationId != null && organizationId.isNotEmpty) {
        requestBody['organization_id'] = organizationId;
        print('🏥 Organization ID parameter added to tests request body: $organizationId');
      }
      
      // Debug logging
      print('🔍 API Request Body: ${jsonEncode(requestBody)}');
      print('🔍 Search parameter: $search');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.diagnosisTests}'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get diagnosis tests',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get organization-specific tests API
  Future<Map<String, dynamic>> getOrganizationTests({
    required String organizationId,
    String? search,
    String sortBy = 'testname',
    String sortOrder = 'asc',
  }) async {
    try {
      final headers = await _headers;
      final requestBody = <String, dynamic>{
        'search': search ?? '',
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      
      print('🏥 API Service: Making organization tests API call to ${ApiConfig.baseUrl}${ApiConfig.organizationTests}$organizationId/tests');
      print('🏥 API Service: Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.organizationTests}$organizationId/tests'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get organization tests',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get organization-specific packages API
  Future<Map<String, dynamic>> getOrganizationPackages({
    required String organizationId,
  }) async {
    try {
      final headers = await _headers;
      
      print('🏥 API Service: Making organization packages API call to ${ApiConfig.baseUrl}${ApiConfig.organizationTests}$organizationId/packages');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.organizationTests}$organizationId/packages'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get organization packages',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get organizations/providers API
  Future<Map<String, dynamic>> getOrganizationsProviders({
    required List<String> testIds,
    required List<String> packageIds,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.organizationsProviders}'),
        headers: headers,
        body: jsonEncode({
          'test_ids': testIds,
          'package_ids': packageIds,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get organizations/providers',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Add item to cart API
  Future<Map<String, dynamic>> addToCart({
    required double price,
    required String testName,
    required String labTestId,
    String? preferredDate,
    String? preferredTime,
    String? packageId,
    String? organizationId,
    String? organizationName,
  }) async {
    try {
      final headers = await _headers;
      
      final requestBody = {
        'price': price,
        'test_name': testName,
        'lab_test_id': packageId != null ? null : labTestId,
        'preferred_date': preferredDate,
        'preferred_time': preferredTime,
        if (packageId != null) 'lab_package_id': packageId,
        if (organizationId != null) 'lab_id': organizationId,
        if (organizationId != null) 'lab_name': organizationName,
      };
      
      print('🔄 Add to Cart API Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cartAdd}'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add item to cart',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get cart API
  Future<Map<String, dynamic>> getCart() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cartGet}'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get cart',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Remove item from cart API
  Future<Map<String, dynamic>> removeFromCart(String itemId) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cartRemove}/$itemId'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to remove item from cart',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Update lab for cart items API
  Future<Map<String, dynamic>> updateCartLab({
    required List<String> labTestIds,
    required String labId,
    required String labName,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cartUpdateLab}'),
        headers: headers,
        body: jsonEncode({
          'cart_item_ids': labTestIds,
          'lab_id': labId,
          'lab_name': labName,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update lab for cart items',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get timeslots for organization API
  Future<Map<String, dynamic>> getOrganizationTimeslots({
    required String orgId,
    required String date,
  }) async {
    print('🔄 API: getOrganizationTimeslots called');
    print('🔄 API: orgId = $orgId');
    print('🔄 API: date = $date');
    
    try {
      final headers = await _headers;
      print('🔄 API: Headers = $headers');
      
      const url = '${ApiConfig.baseUrl}${ApiConfig.organizationsTimeslots}';
      print('🔄 API: URL = $url');
      
      final requestBody = {
        'org_id': orgId,
        'date': date,
      };
      print('🔄 API: Request body = $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🔄 API: Response status = ${response.statusCode}');
      print('🔄 API: Response body = ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('🔄 API: Success response');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        print('🔄 API: Error response');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get timeslots',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('🔄 API: Exception = $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Check if user profile is complete
  static bool isProfileComplete(Map<String, dynamic> userData) {
    final firstName = userData['firstName']?.toString();
    final lastName = userData['lastName']?.toString();
    final email = userData['email']?.toString();
    final dateOfBirth = userData['dateOfBirth']?.toString();
    final gender = userData['gender']?.toString();
    
    // Profile is complete if firstName exists and is not empty
    return firstName != null && firstName.isNotEmpty;
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers ?? defaultHeaders,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Apply Promo Code API
  Future<Map<String, dynamic>> applyPromoCode({
    required String promoCode,
    required double totalAmount,
    required List<String> testIds,
    required List<String> packageIds,
    required String labId,
    required String cartId,
    required String paymentMethod,
    BuildContext? context,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.applyPromo}'),
        headers: headers,
        body: jsonEncode({
          'promo_code': promoCode,
          'total_amount': totalAmount,
          'tests': testIds,
          'packages': packageIds,
          'lab_id': labId,
          'cart_id': cartId,
          'payment_method': paymentMethod,
        }),
      );

      return _handleResponse(response, context);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _headers;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers ?? defaultHeaders,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _headers;
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers ?? defaultHeaders,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final defaultHeaders = await _headers;
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers ?? defaultHeaders,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get Dependents API
  Future<Map<String, dynamic>> getDependents(BuildContext? context) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dependents}'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      // Handle the new response structure
      if (response.statusCode == 200) {
        return {
          'success': responseData['status'] == 'success',
          'status': responseData['status'],
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Add Dependent API
  Future<Map<String, dynamic>> addDependent({
    required String firstName,
    required String lastName,
    required int relationshipId,
    required String contactNumber,
    required String dateOfBirth,
    required String gender,
    String? email,
    BuildContext? context,
  }) async {
    try {
      final headers = await _headers;
      final data = {
        'first_name': firstName,
        'last_name': lastName,
        'relationship_id': relationshipId,
        'contact_number': contactNumber,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addDependent}'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response, context);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Delete Dependent API
  Future<Map<String, dynamic>> deleteDependent({
    required String dependentId,
    BuildContext? context,
  }) async {
    try {
      print('🗑️ Delete Dependent API: Deleting dependent with ID: $dependentId');
      
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dependents}/$dependentId'),
        headers: headers,
      );

      print('🗑️ Delete Dependent API Response Status: ${response.statusCode}');
      print('🗑️ Delete Dependent API Response Body: ${response.body}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error deleting dependent: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Update Dependent API
  Future<Map<String, dynamic>> updateDependent({
    required String dependentId,
    required String firstName,
    required String lastName,
    required int relationshipId,
    required String contactNumber,
    required String dateOfBirth,
    required String gender,
    String? email,
    BuildContext? context,
  }) async {
    try {
      print('✏️ Update Dependent API: Updating dependent with ID: $dependentId');
      print('✏️ Update Dependent API: Request data:');
      print('  - First Name: $firstName');
      print('  - Last Name: $lastName');
      print('  - Relationship ID: $relationshipId');
      print('  - Contact: $contactNumber');
      print('  - DOB: $dateOfBirth');
      print('  - Gender: $gender');
      print('  - Email: $email');
      
      final headers = await _headers;
      final data = {
        'first_name': firstName,
        'last_name': lastName,
        'relationship_id': relationshipId,
        'contact_number': contactNumber,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dependents}/$dependentId'),
        headers: headers,
        body: jsonEncode(data),
      );

      print('✏️ Update Dependent API Response Status: ${response.statusCode}');
      print('✏️ Update Dependent API Response Body: ${response.body}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error updating dependent: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get User Addresses API
  Future<Map<String, dynamic>> getUserAddresses(BuildContext? context) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileAddresses}'),
        headers: headers,
      );

      return _handleResponse(response, context);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Add Address API
  Future<Map<String, dynamic>> addAddress({
    required String type,
    String? name,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    String? country,
    required String pincode,
    bool isPrimary = false,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? contactNumber,
    BuildContext? context,
  }) async {
    try {
      final headers = await _headers;
      final data = {
        'type': type,
        if (name != null && name.isNotEmpty) 'name': name,
        'address_line1': addressLine1,
        if (addressLine2 != null && addressLine2.isNotEmpty) 'address_line2': addressLine2,
        'city': city,
        'state': state,
        if (country != null && country.isNotEmpty) 'country': country,
        'pincode': pincode,
        'is_primary': isPrimary,
        if (postalCode != null && postalCode.isNotEmpty) 'postal_code': postalCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (contactNumber != null && contactNumber.isNotEmpty) 'contact_number': contactNumber,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addAddress}'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response, context);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Delete Address API
  Future<Map<String, dynamic>> deleteAddress({
    required String addressId,
    BuildContext? context,
  }) async {
    try {
      print('🗑️ Delete Address API: Deleting address with ID: $addressId');
      
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileAddresses}/$addressId'),
        headers: headers,
      );

      print('🗑️ Delete Address API Response Status: ${response.statusCode}');
      print('🗑️ Delete Address API Response Body: ${response.body}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error deleting address: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Update Address API
  Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String type,
    String? name,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    String? country,
    required String pincode,
    bool isPrimary = false,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? contactNumber,
    BuildContext? context,
  }) async {
    try {
      print('✏️ Update Address API: Updating address with ID: $addressId');
      print('✏️ Update Address API: Request data:');
      print('  - Type: $type');
      print('  - Name: $name');
      print('  - Address Line 1: $addressLine1');
      print('  - Address Line 2: $addressLine2');
      print('  - City: $city');
      print('  - State: $state');
      print('  - Country: $country');
      print('  - Pincode: $pincode');
      print('  - Is Primary: $isPrimary');
      print('  - Contact Number: $contactNumber');
      
      final headers = await _headers;
      final data = {
        'type': type,
        if (name != null && name.isNotEmpty) 'name': name,
        'address_line1': addressLine1,
        if (addressLine2 != null && addressLine2.isNotEmpty) 'address_line2': addressLine2,
        'city': city,
        'state': state,
        if (country != null && country.isNotEmpty) 'country': country,
        'pincode': pincode,
        'is_primary': isPrimary,
        if (postalCode != null && postalCode.isNotEmpty) 'postal_code': postalCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (contactNumber != null && contactNumber.isNotEmpty) 'contact_number': contactNumber,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileAddresses}/$addressId'),
        headers: headers,
        body: jsonEncode(data),
      );

      print('✏️ Update Address API Response Status: ${response.statusCode}');
      print('✏️ Update Address API Response Body: ${response.body}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error updating address: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Clear Cart API
  Future<Map<String, dynamic>> clearCart(BuildContext? context) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cartGet}'),
        headers: headers,
      );

      print('🛒 Clear Cart API Response Status: ${response.statusCode}');
      print('🛒 Clear Cart API Response Body: ${response.body}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error clearing cart: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get Referral Stats API
  Future<Map<String, dynamic>> getReferralStats(BuildContext? context) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.referralStats}'),
        headers: headers,
      );

      print('📊 Referral Stats API Response Status: ${response.statusCode}');
      print('📊 Referral Stats API Response Body: ${response.body}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error getting referral stats: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  // Get Relationships API
  Future<Map<String, dynamic>> getRelationships(BuildContext? context) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.relationships}'),
        headers: headers,
      );

      print('👥 Relationships API Response Status: ${response.statusCode}');
      print('👥 Relationships API Response Body: ${_handleResponse(response, context)}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error getting relationships: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }



  // Create Appointment API
  Future<Map<String, dynamic>> createAppointment({
    required String labId,
    required String cartId,
    required List<String> labTests,
    required List<String> packages,
    required String patient,
    required bool isHomeCollection,
    required String address,
    required String appointmentDate,
    required String appointmentTime,
    required bool isUseWallet,
    required String paymentMode,
    String? couponCode,
    required double amountPayable,
    BuildContext? context,
  }) async {
    try {
      final headers = await _headers;
      final data = {
        'lab_id': labId,
        'cart_id': cartId,
        'lab_test': labTests,
        'packages': packages,
        'patient': patient,
        'is_home_collection': isHomeCollection,
        'address': address,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'is_use_wallet': isUseWallet,
        'payment_mode': paymentMode,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
        'amountPayable': amountPayable,
      };

      print('📋 Creating appointment with data: $data');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createAppointment}'),
        headers: headers,
        body: jsonEncode(data),
      );

      print('📋 Appointment API Response Status: ${response.statusCode}');
      print('📋 Appointment API Response Body: ${response.body}');

      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error creating appointment: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> bookMultiLabAppointment(Map<String, dynamic> bookingData) async {
    try {
      print('🔄 Booking multi-lab appointment with data: $bookingData');
      
      final headers = await _headers;
      
      // Use the multi-lab appointment endpoint
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.multiLabAppointment}'),
        headers: headers,
        body: json.encode(bookingData),
      );

      print('📊 Multi-lab booking response status: ${response.statusCode}');
      print('📊 Multi-lab booking response body: ${response.body}');
      
      // Check if this is a network connectivity issue
      if (response.statusCode == 0) {
        return {
          'success': false,
          'message': 'Network connection failed. Please check your internet connection.',
          'error': 'Connection timeout or no internet',
        };
      }
      
      // Check for server errors
      if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': 'Server error occurred. Please try again later.',
          'error': 'Server error ${response.statusCode}',
        };
      }
      
      return _handleResponse(response, null);
    } catch (e) {
      print('❌ Error booking multi-lab appointment: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
        }
  }

  // Get Appointment Details API
  Future<Map<String, dynamic>> getAppointmentDetails({
    required String appointmentId,
    BuildContext? context,
  }) async {
    try {
      print('🔄 Fetching appointment details for ID: $appointmentId');
      
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/appointments/$appointmentId/details'),
        headers: headers,
      );

      print('📊 Appointment details response status: ${response.statusCode}');
      print('📊 Appointment details response body: ${response.body}');
      
      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error fetching appointment details: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }
  
  // Cancel Appointment API
  Future<Map<String, dynamic>> cancelAppointment({
    required String appointmentId,
    required String cancellationReason,
    required bool refundToWallet,
    BuildContext? context,
  }) async {
    try {
      print('🔄 Cancelling appointment with ID: $appointmentId');
      print('🔄 Cancellation reason: $cancellationReason');
      print('🔄 Refund to wallet: $refundToWallet');
      
      final headers = await _headers;
      final requestBody = {
        'cancellation_reason': cancellationReason,
        'refund_to_wallet': refundToWallet,
      };
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/mobile/appointments/$appointmentId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('📊 Cancel appointment response status: ${response.statusCode}');
      print('📊 Cancel appointment response body: ${response.body}');
      
      return _handleResponse(response, context);
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }
} 