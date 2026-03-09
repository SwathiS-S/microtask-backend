enum UserRole { taskUser, taskProvider, admin }

class UserService {
  static String? _userId;
  static String? _userName;
  static String? _userEmail;
  static String? _userPassword;
  static String? _userLocation;
  static String? _userPhone;
  static Map<String, dynamic>? _bankDetails;
  static double _walletBalance = 0.0;
  static String _memberSince = 'Jan 2026';
  static UserRole _userRole = UserRole.taskUser;

  // Getters
  static String? get userId => _userId;
  static String? get userName => _userName;
  static String? get userEmail => _userEmail;
  static String? get userPhone => _userPhone;
  static String? get userPassword => _userPassword;
  static String? get userLocation => _userLocation;
  static Map<String, dynamic>? get bankDetails => _bankDetails;
  static double get walletBalance => _walletBalance;
  static String get memberSince => _memberSince;
  static UserRole get userRole => _userRole;
  static bool get isTaskProvider => _userRole == UserRole.taskProvider;
  static bool get isAdmin => _userRole == UserRole.admin;

  // Setters
  static void setUser({
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userPassword,
    String? userLocation,
    Map<String, dynamic>? bankDetails,
    double? walletBalance,
    String? memberSince,
    UserRole? userRole,
  }) {
    if (userId != null) _userId = userId;
    if (userName != null) _userName = userName;
    if (userEmail != null) _userEmail = userEmail;
    if (userPhone != null) _userPhone = userPhone;
    if (userPassword != null) _userPassword = userPassword;
    if (userLocation != null) _userLocation = userLocation;
    if (bankDetails != null) _bankDetails = bankDetails;
    if (walletBalance != null) _walletBalance = walletBalance;
    if (memberSince != null) _memberSince = memberSince;
    if (userRole != null) _userRole = userRole;
  }

  static void updateProfile({
    String? userName,
    String? userEmail,
  }) {
    if (userName != null) _userName = userName;
    if (userEmail != null) _userEmail = userEmail;
  }

  static void updatePassword(String password) {
    _userPassword = password;
  }

  static void updateWalletBalance(double balance) {
    _walletBalance = balance;
  }

  static void clearUser() {
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userPassword = null;
    _userLocation = null;
    _walletBalance = 0.0;
    _memberSince = 'Jan 2026';
    _userRole = UserRole.taskUser;
  }
}
