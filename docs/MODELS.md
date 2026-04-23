# Data Models Reference

All data models are located in `lib/core/models/`. Models use `equatable` for value equality and provide `toJson()` / `fromJson()` serialization.

---

## Authentication Models

**File**: `auth_models.dart`

| Model | Fields | Description |
|---|---|---|
| `LoginRequest` | `userID`, `password`, `appRegId` | Login API request payload |
| `LoginResponse` | `msg`, `data` (UserData) | Login API response |
| `AutoLoginRequest` | `appRegId` | Auto-login request payload |
| `LogoutRequest` | `appRegId` | Logout request payload |
| `UserData` | `emplName`, `areaCode`, `roles[]`, `pages[]`, `userID?`, `appRegId?` | Authenticated user profile |

**UserData Methods**: `hasRole()`, `hasPage()`, `hasAnyRole()`, `hasAnyPage()`

---

## Trade Partner Models

**File**: `trade_partner_models.dart` (792 lines)

### Product Models

| Model | Key Fields |
|---|---|
| `ProductCategory` | `id`, `name`, `productCount` |
| `Product` | `id`, `name`, `description`, `categoryId`, `categoryName`, `price`, `mrp`, `unit`, `isAvailable`, `stockQuantity`, `sku` |

### Order Models

| Model | Key Fields |
|---|---|
| `OrderItem` | `productId`, `productName`, `quantity`, `unitPrice`, `totalPrice` |
| `Order` | `id`, `orderNumber`, `orderDate`, `status`, `items[]`, `totalAmount`, `netAmount`, `expectedDeliveryDate`, `lrNumber` |

**Enum `OrderStatus`**: `placed`, `approved`, `dispatched`, `delivered`, `cancelled`

### Ledger Models

| Model | Key Fields |
|---|---|
| `LedgerEntry` | `id`, `date`, `type`, `description`, `amount`, `balance` |
| `LedgerSummary` | `totalOutstanding`, `overdueAmount`, `creditLimit`, `availableCredit`, `totalInvoices`, `overdueInvoices` |

**Enum `LedgerEntryType`**: `invoice`, `payment`, `creditNote`, `debitNote`, `adjustment`

### Scheme Models

| Model | Key Fields |
|---|---|
| `Scheme` | `id`, `name`, `type`, `description`, `startDate`, `endDate`, `terms` |

**Enum `SchemeType`**: `discount`, `cashback`, `gift`, `bonus`, `combo`

### Grievance Models

| Model | Key Fields |
|---|---|
| `Grievance` | `id`, `category`, `status`, `description`, `attachments`, `responses` |
| `CreateGrievanceRequest` | *(request payload for filing grievances)* |

**Enum `GrievanceCategory`**: `product`, `delivery`, `payment`, `service`, `other`

**Enum `GrievanceStatus`**: `open`, `inProgress`, `resolved`, `closed`

---

## Market Mapping Models

**File**: `market_mapping_models.dart` (13 KB)

Models for competitor pricing, new product launches, discount tracking, and market intelligence reports.

---

## Sales Monitoring Models

**File**: `sales_monitoring_models.dart` (12 KB)

Data models for counter mapping, visit planning, and route tracking in sales operations.

---

## Stock Models

**File**: `stock_models.dart` (10 KB)

Inventory models for stock entry, stock levels, and aging stock reporting.

---

## Product Journey Models

**File**: `product_journey_models.dart` (7.5 KB)

Product lifecycle tracking models covering manufacturing to delivery stages.

---

## Profile & User Models

### Profile Details
**File**: `profile_details_models.dart` (14 KB)

Extended user profile information models.

### User Profile
**File**: `user_profile_models.dart` (8.5 KB)

User profile summary models.

### Admin User Models
**File**: `admin_user_models.dart` (14 KB)

Admin-level user management data models for the user list and edit screens.

---

## Registration Models

### Contractor Models
**File**: `contractor_models.dart` (14 KB)

Contractor registration and profile data models.

### Painter Models
**File**: `painter_models.dart` (7.7 KB)

Painter registration and profile data models.

### Retailer Onboarding Models
**File**: `retailer_onboarding_models.dart` (4.3 KB)

Retailer registration models.

---

## Other Models

| File | Size | Description |
|---|---|---|
| `approval_models.dart` | 9 KB | Approval workflow data models |
| `dashboard_models.dart` | 3.3 KB | Dashboard metrics and statistics |
| `kyc_status_models.dart` | 1.2 KB | KYC verification status |
| `sample_distribution_models.dart` | 2.4 KB | Sample distribution campaign data |
| `sampling_drive_models.dart` | 6.6 KB | Sampling drive execution data |

---

## User Management Models

**File**: `features/user_management/user_list_models.dart` (12 KB)

Dedicated models for the admin user list feature (separate from core models).
