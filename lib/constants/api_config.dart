class ApiConfig {
  // Base URL
  static const String baseUrl = 'http://localhost:3000/api/v1';
  
  // Auth endpoints
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/update-profile';
  static const String completeProfile = '/mobile/profile/complete';
  static const String mobileProfile = '/mobile/profile';
  
  // Orders endpoints
  static const String orders = '/orders';
  static const String orderDetail = '/orders/';
  
  // Tests endpoints
  static const String tests = '/tests';
  static const String packages = '/packages';
  
  // Labs endpoints
  static const String labs = '/labs';
  static const String labDetail = '/labs/';
  
  // Wallet endpoints
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  
  // Family members endpoints
  static const String familyMembers = '/family-members';
  static const String dependents = '/profile/dependents';
  static const String addDependent = '/profile/dependents';
  static const String relationships = '/mobile/relationships';
  
  // Addresses endpoints
  static const String addresses = '/addresses';
  static const String profileAddresses = '/profile/addresses';
  static const String addAddress = '/profile/addresses';
  
  // Medical records endpoints
  static const String medicalRecords = '/medical-records';
  
  // Coupons endpoints
  static const String coupons = '/coupons';
  static const String applyCoupon = '/coupons/apply';
  static const String applyPromo = '/appointments/apply-promo';
  
  // Banners endpoints
  static const String banners = '/mobile/banners';
  
  // Tests endpoints
  static const String topTests = '/mobile/top-tests';
  static const String diagnosisTests = '/diagnosis-tests/public/active';
  
  // Packages endpoints
  static const String topPackages = '/mobile/top-packages';
  static const String mobilePackages = '/mobile/packages';
  
  // Lab/Provider endpoints
  static const String organizationsProviders = '/mobile/organizations/providers';
  static const String organizationsTimeslots = '/mobile/organizations/timeslots';
  
  // Cart endpoints
  static const String cartAdd = '/mobile/cart/add';
  static const String cartGet = '/mobile/cart';
  static const String cartRemove = '/mobile/cart/remove';
  static const String cartUpdateLab = '/mobile/cart/update-lab';
  
  // Package organizations endpoint
  static const String packageOrganizations = '/organization-packages/package/organizations';
  
  // Appointment history endpoint
  static const String appointmentHistory = '/mobile/appointments/history';
  
  // Mobile wallet endpoint
  static const String mobileWallet = '/mobile/wallet';
  
  // Add money to wallet endpoint
  static const String addMoneyToWallet = '/mobile/wallet/add-money';
  
  // Appointments endpoints
  static const String createAppointment = '/mobile/appointments';
  
  // Referral endpoints
  static const String referralStats = '/mobile/referrals/stats';
} 