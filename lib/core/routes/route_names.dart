/// Route Names
/// Define all route names as constants
class RouteNames {
  // Root - Splash Screen
  static const String splash = '/';

  // Auth
  static const String login = '/login';
  static const String loginWithPassword = '/login-with-password';
  static const String loginWithOtp = '/login-with-otp';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String contractorRegistration = '/contractor-registration';
  static const String painterRegistration = '/painter-registration';
  static const String retailerRegistration = '/retailer-registration';
  static const String registrationType = '/registration-type';
  static const String painterUpdate = '/painter-update';
  static const String contractorUpdate = '/contractor-update';

  // Main
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String dashboard = '/dashboard';
  static const String approvalDashboard = '/approval-dashboard';
  static const String cameraScanner = '/camera-scanner';
  static const String notifications = '/notifications';
  static const String productDetails = '/product-details';

  // Role specific home screens
  static const String contractorHome = '/contractor-home';
  static const String painterHome = '/painter-home';

  // Admin screens
  static const String adminUserEdit = '/admin-user-edit';

  // Trade Partner Journey
  static const String tradePartnerHome = '/trade-partner-home';
  static const String products = '/products';
  static const String placeOrder = '/place-order';
  static const String orders = '/orders';
  static const String orderDetails = '/order/:orderId';
  static const String ledger = '/ledger';
  static const String schemes = '/schemes';
  static const String grievances = '/grievances';
  static const String grievanceDetails = '/grievance/:grievanceId';

  // Stock Visibility
  static const String stockEntry = '/stock-entry';
  static const String agingStock = '/aging-stock';

  // Market Mapping
  static const String marketMappingHome = '/market-mapping-home';
  static const String competitorPricing = '/competitor-pricing';
  static const String newLaunches = '/new-launches';
  static const String discountTracking = '/discount-tracking';
  static const String marketIntelligence = '/market-intelligence';

  // Sales Monitoring
  static const String salesMonitoringHome = '/sales-monitoring-home';
  static const String counterMapping = '/counter-mapping';
  static const String visitPlanning = '/visit-planning';
  static const String routeTracking = '/route-tracking';

  // Product Journey Tracking
  static const String productJourney = '/product-journey';
}
