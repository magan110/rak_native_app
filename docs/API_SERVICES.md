# API Services Reference

Complete reference for all core services in `lib/core/services/`.

---

## Authentication & Session

### `AuthService`
**File**: `auth_service.dart` (645 lines)

Handles user authentication, session management, and server communication.

| Method | Description |
|---|---|
| `authenticateUser({userID, password, appRegId})` | Primary login with credentials |
| `autoLogin()` | Auto-login using stored `appRegId` |
| `login(userId, password)` | Simplified login wrapper |
| `loginWithOtp(mobile, otp)` | OTP-based authentication |
| `sendOtp(mobile)` | Request OTP to mobile number |
| `logout()` | Clear local session |
| `logoutFromServer()` | Server-side session termination |
| `validateSession()` | Check if current session is valid |
| `refreshToken()` | Refresh authentication token |
| `testConnection()` | Test API server connectivity |
| `refreshSslClient()` | Force refresh the SSL HTTP client |
| `testSslConnection()` | Verify SSL connectivity |

### `AuthManager` (Singleton)
Part of `auth_service.dart`. Manages current user state in memory.

| Method | Description |
|---|---|
| `setUser(userData, {token})` | Set current authenticated user |
| `clearUser()` | Clear current user session |
| `hasRole(role)` | Check if user has a specific role |
| `hasPage(page)` | Check if user has access to a page |
| `hasAnyRole(roles)` | Check against multiple roles |
| `hasAnyPage(pages)` | Check against multiple pages |
| `getUserRoles()` | Get list of user roles |
| `getUserPages()` | Get list of accessible pages |
| `getUserName()` | Get current user's display name |
| `getUserAreaCode()` | Get current user's area code |

### `AutoLoginService`
**File**: `autologin_service.dart`

Manages automatic re-authentication using stored device registration IDs and hash-based verification.

### `StorageService`
**File**: `storage_service.dart` (366 lines)

Local persistence layer using `SharedPreferences`.

| Method | Description |
|---|---|
| `generateAppRegId()` | Generate unique device registration ID |
| `saveAppRegId(appRegId)` / `getAppRegId()` | Persist/retrieve registration ID |
| `saveUserId(userId)` / `getUserId()` | Remember me functionality |
| `saveRememberMe(bool)` / `getRememberMe()` | Remember me preference |
| `clearAllAuthData()` | Wipe all auth data |
| `canAutoLogin()` | Check auto-login feasibility |
| `generateAutoLoginHash({userId, userType})` | Create secure auto-login hash |
| `saveAutoLoginData({userId, userType, userData})` | Store auto-login credentials |
| `validateAutoLogin()` | Validate stored auto-login data |

---

## OCR & Document Processing

### `EmiratesIdOcrService`
**File**: `emirates_id_ocr_service.dart` (22 KB)

Extracts data from UAE Emirates ID cards using on-device ML Kit text recognition.

### `BankDetailsOcrService`
**File**: `bank_details_ocr_service.dart` (15 KB)

Extracts bank account details from cheque images or bank documents.

### `VatCertificateOcrService`
**File**: `vat_certificate_ocr_service.dart` (15 KB)

Parses VAT registration certificate documents.

### `CommercialLicenceOcrService`
**File**: `commercial_licence_ocr_service.dart`

Extracts data from UAE commercial/trade licence documents.

### `GeminiOcrService`
**File**: `gemini_ocr_service.dart` (11 KB)

Cloud-based OCR using Google Gemini AI as a fallback for on-device processing failures.

### `HybridOcrService`
**File**: `hybrid_ocr_service.dart` (14 KB)

Combines ML Kit (on-device) and Gemini (cloud) OCR for optimal extraction accuracy with automatic fallback.

---

## Business Services

### `TradePartnerService`
**File**: `trade_partner_service.dart` (559 lines)

Full B2B trade partner workflow API.

| Method | Description |
|---|---|
| `getCategories()` | Fetch product categories |
| `getProducts({categoryId})` | Fetch products by category |
| `searchProducts(query)` | Search product catalogue |
| `placeOrder({cartItems, remarks})` | Submit a new order |
| `getOrders({status})` | Fetch order history |
| `getOrderDetails(orderId)` | Single order details |
| `getLedgerSummary()` | Financial summary |
| `getLedgerEntries({fromDate, toDate})` | Ledger transactions |
| `getStatementOfAccount({fromDate, toDate})` | Generate SOA |
| `getActiveSchemes()` | Current promotions |
| `getAllSchemes()` | All schemes including expired |
| `submitGrievance(request)` | File a complaint |
| `getGrievances({status})` | Fetch complaints |
| `getGrievanceDetails(grievanceId)` | Single grievance details |

### `MarketMappingService`
**File**: `market_mapping_service.dart` (12 KB)

Market intelligence data collection and retrieval.

### `SalesMonitoringService`
**File**: `sales_monitoring_service.dart` (10 KB)

Sales team operations: counter mapping, visit planning, route tracking.

### `StockService`
**File**: `stock_service.dart` (13 KB)

Inventory management: stock entry and aging stock tracking.

### `ProductJourneyService`
**File**: `product_journey_service.dart` (9 KB)

Product lifecycle tracking through the supply chain.

### `ContractorService`
**File**: `contractor_service.dart` (13 KB)

Contractor profile management and registration flows.

### `PainterService`
**File**: `painter_service.dart` (11 KB)

Painter profile management and registration.

### `RetailerOnboardingService`
**File**: `retailer_onboarding_service.dart` (13 KB)

Retailer registration and onboarding process.

### `ActivityService`
**File**: `activity_service.dart` (5 KB)

User activity logging and reporting.

### `SampleDistributionService`
**File**: `sample_distribution_service.dart`

Sample product distribution campaign management.

### `SamplingExecutionService`
**File**: `sampling_execution_service.dart` (8 KB)

Sample collection execution tracking.

### `DashboardService`
**File**: `dashboard_service.dart`

Dashboard data aggregation and metrics.

### `ApprovalService`
**File**: `approval_service.dart` (13 KB)

Approval workflow management for various business processes.

### `AdminUserService`
**File**: `admin_user_service.dart` (6.5 KB)

Admin CRUD operations on user accounts.

### `ProfileDetailsService`
**File**: `profile_details_service.dart`

User profile information management.

### `ProfileCompletionService`
**File**: `profile_completion_service.dart`

Track and calculate profile completion percentage.

### `KycStatusService`
**File**: `kyc_status_service.dart`

KYC verification status checking.

---

## Infrastructure Services

### `ImageUploadService`
**File**: `image_upload_service.dart` (10 KB)

Image upload to backend with multipart form handling.

### `SmsUaeService`
**File**: `sms_uae_service.dart` (16 KB)

UAE SMS gateway integration for OTP delivery.

| Method | Description |
|---|---|
| `verifyMobile(mobile)` | Verify mobile number in system |
| `routeByMobile(mobile)` | Determine user route by mobile |
| `sendSms(mobile, message)` | Send SMS message |
| `sendIfRegistered(mobile)` | Send OTP only if registered |

### `LocationService`
**File**: `location_service.dart`

GPS location services and permission management using `geolocator`.

### `MaintenanceService`
**File**: `maintenance_service.dart`

Server maintenance mode detection via `/api/RakUnderMaintainance/status`.

---

## Network Layer

### `ApiClient`
**File**: `network/api_client.dart`

HTTP client with JSON serialization and error handling.

| Method | Description |
|---|---|
| `get(endpoint, {headers, queryParameters})` | HTTP GET |
| `post(endpoint, {headers, body})` | HTTP POST |
| `put(endpoint, {headers, body})` | HTTP PUT |
| `delete(endpoint, {headers})` | HTTP DELETE |
| `createWithSsl({baseUrl})` | Factory with SSL client |

### `SslHttpClient`
**File**: `network/ssl_http_client.dart`

SSL certificate pinning for secure API communication.

- Loads PEM certificate from `assets/cert/rak_cer.pem`
- Allows connections to `birlawhite.com` domain
- Three-tier fallback: SSL → permissive SSL → default HTTP
- 30-second connection and idle timeouts

---

## API Configuration

**Base URL**: `https://qa.birlawhite.com:55232`

### Key Endpoints (from `api_config.dart`)

| Endpoint | Purpose |
|---|---|
| `/api/SmsUae/verify-mobile` | Mobile verification |
| `/api/SmsUae/route-by-mobile` | User routing |
| `/api/SmsUae/send` | Send SMS |
| `/api/SmsUae/send-if-registered` | Conditional SMS |
| `/api/SmsUae/health` | Health check |
| `/api/RakUnderMaintainance/status` | Maintenance mode check |
| `/api/ImageUpload/upload` | Image upload |
| `/api/Auth/login` | Authentication |
| `/api/Auth/auto-login` | Auto-login |
| `/api/Auth/logout` | Server logout |

### HTTP Headers

Standard headers include browser-like `User-Agent`, CORS headers (`Origin`, `Sec-Fetch-*`), and cache-busting directives to bypass WAF/security systems.

### Timeouts

| Setting | Duration |
|---|---|
| Default timeout | 15 seconds |
| SMS timeout | 20 seconds |
| SSL connection timeout | 30 seconds |
| OTP TTL | 5 minutes |
| OTP resend cooldown | 30 seconds |
