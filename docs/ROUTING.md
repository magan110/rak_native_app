# Navigation & Routing

The RAK App uses [go_router](https://pub.dev/packages/go_router) `^16.2.5` for declarative, URL-based navigation.

---

## Configuration

- **Router file**: `lib/core/routes/app_router.dart` (470 lines)
- **Route names**: `lib/core/routes/route_names.dart`
- **Router type**: `MaterialApp.router` with `GoRouter`

---

## Route Map

### Root & Authentication

| Route | Name | Screen | Description |
|---|---|---|---|
| `/` | `splash` | `SplashScreen` | App entry, auto-login check |
| `/login` | `login` | — | Login route |
| `/login-with-password` | `loginWithPassword` | `LoginWithPasswordScreen` | User ID + password |
| `/login-with-otp` | `loginWithOtp` | `LoginScreenWithOtp` | Mobile + OTP |

### Registration

| Route | Name | Screen |
|---|---|---|
| `/register` | `register` | — |
| `/registration-type` | `registrationType` | `RegistrationTypeScreen` |
| `/contractor-registration` | `contractorRegistration` | `ContractorRegistrationScreen` |
| `/painter-registration` | `painterRegistration` | `PainterRegistrationScreen` |
| `/retailer-registration` | `retailerRegistration` | `RetailerRegistrationScreen` |
| `/forgot-password` | `forgotPassword` | — |
| `/contractor-update` | `contractorUpdate` | `ContractorUpdateScreen` |
| `/painter-update` | `painterUpdate` | `PainterUpdateScreen` |

### Main Screens

| Route | Name | Screen |
|---|---|---|
| `/home` | `home` | `HomeScreen` |
| `/profile` | `profile` | — |
| `/settings` | `settings` | — |
| `/dashboard` | `dashboard` | `Dashboard` |
| `/approval-dashboard` | `approvalDashboard` | `ApprovalDashboard` |
| `/camera-scanner` | `cameraScanner` | `CameraScanner` |
| `/notifications` | `notifications` | `NotificationsScreen` |
| `/product-details` | `productDetails` | `ProductDetailsScreen` |

### Role-Specific Home Screens

| Route | Name | Screen | Role |
|---|---|---|---|
| `/contractor-home` | `contractorHome` | `ContractorHomeScreen` | Contractor |
| `/painter-home` | `painterHome` | `PainterHomeScreen` | Painter |
| `/trade-partner-home` | `tradePartnerHome` | `TradePartnerHomeScreen` | Trade Partner |

### Trade Partner Journey

| Route | Name | Screen |
|---|---|---|
| `/products` | `products` | `ProductCatalogScreen` |
| `/place-order` | `placeOrder` | `PlaceOrderScreen` |
| `/orders` | `orders` | `OrderHistoryScreen` |
| `/order/:orderId` | `orderDetails` | — |
| `/ledger` | `ledger` | `LedgerScreen` |
| `/schemes` | `schemes` | `SchemesScreen` |
| `/grievances` | `grievances` | `GrievanceScreen` |
| `/grievance/:grievanceId` | `grievanceDetails` | — |

### Stock Visibility

| Route | Name | Screen |
|---|---|---|
| `/stock-entry` | `stockEntry` | — |
| `/aging-stock` | `agingStock` | — |

### Market Mapping

| Route | Name | Screen |
|---|---|---|
| `/market-mapping-home` | `marketMappingHome` | `MarketMappingHomeScreen` |
| `/competitor-pricing` | `competitorPricing` | `CompetitorPricingScreen` |
| `/new-launches` | `newLaunches` | `NewLaunchesScreen` |
| `/discount-tracking` | `discountTracking` | `DiscountTrackingScreen` |
| `/market-intelligence` | `marketIntelligence` | `MarketIntelligenceScreen` |

### Sales Monitoring

| Route | Name | Screen |
|---|---|---|
| `/sales-monitoring-home` | `salesMonitoringHome` | — |
| `/counter-mapping` | `counterMapping` | — |
| `/visit-planning` | `visitPlanning` | — |
| `/route-tracking` | `routeTracking` | — |

### Admin

| Route | Name | Screen |
|---|---|---|
| `/admin-user-edit` | `adminUserEdit` | — |

### Product Journey

| Route | Name | Screen |
|---|---|---|
| `/product-journey` | `productJourney` | `ProductJourneyScreen` |

---

## Navigation Helpers

### `AppRouter.notifyAuthChange()`
Notifies the router that authentication state has changed, triggering route re-evaluation and redirects.

### `AppRouter.logout(BuildContext context)`
Clears the user session and navigates to the login screen.

---

## Route Parameters

Some routes accept dynamic parameters:

| Route | Parameter | Type | Example |
|---|---|---|---|
| `/order/:orderId` | `orderId` | `String` | `/order/ORD001` |
| `/grievance/:grievanceId` | `grievanceId` | `String` | `/grievance/GRV001` |

---

## Usage Examples

```dart
// Navigate to a named route
context.go(RouteNames.home);

// Navigate with parameters
context.go(RouteNames.orderDetails.replaceAll(':orderId', orderId));

// Push a screen onto the stack
context.push(RouteNames.productDetails);

// Programmatic logout
AppRouter.logout(context);
```
