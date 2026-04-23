# Feature Modules

This document covers all feature modules in the RAK App, listing their screens, key functionality, and associated services/models.

---

## 1. Core Screens (`features/screens/`)

The main app screens follow a clean data/domain/presentation architecture.

### Login Screens

| Screen | File | Description |
|---|---|---|
| Login with OTP | `login_screen_with_otp.dart` | Mobile number + OTP authentication flow |
| Login with Password | `login_with_password_screen.dart` | User ID + password authentication |

### Main Screens

| Screen | File | Description |
|---|---|---|
| Splash Screen | `splash_screen.dart` | App launch, auto-login check, route determination |
| Home Screen | `home_screen.dart` | Main dashboard for general users |
| Contractor Home | `contractor_home_screen.dart` | Dashboard tailored for contractors |
| Painter Home | `painter_home_screen.dart` | Dashboard tailored for painters |
| Notifications | `notifications_screen.dart` | Push notification list |
| Product Details | `product_details_screen.dart` | Individual product detail view |
| Camera Scanner | `camera_scanner.dart` | QR/barcode scanning via camera |

### Registration Screens

| Screen | File | Description |
|---|---|---|
| Registration Type Selection | `registration_type_screen.dart` | Choose user type (Contractor, Painter, Retailer) |
| Contractor Registration | `contractor_registration_screen.dart` | Multi-step contractor onboarding with document upload |
| Painter Registration | `painter_registration_screen.dart` | Multi-step painter onboarding |
| Retailer Registration | `retailer_registration_screen.dart` | Retailer onboarding flow |
| Registration Details | `registration_details_screen.dart` | Detailed registration form |
| Contractor Update | `contractor_update_screen.dart` | Edit contractor profile |
| Painter Update | `painter_update_screen.dart` | Edit painter profile |
| Success Screen | `success_screen.dart` | Post-registration confirmation |

### Admin Screens

| Screen | File | Description |
|---|---|---|
| Admin User Edit | `admin_screens/` | Admin-level user editing |

---

## 2. Trade Partner Journey (`features/trade_partner_journey/`)

Full B2B trade partner workflow with product ordering, financial ledger, promotional schemes, and grievance management.

**Service**: `TradePartnerService` · **Models**: `trade_partner_models.dart`

| Screen | File | Description |
|---|---|---|
| Trade Partner Home | `trade_partner_home_screen.dart` | Dashboard with quick actions |
| Product Catalogue | `product_catalog_screen.dart` | Browse products by category |
| Place Order | `place_order_screen.dart` | Cart and order placement |
| Order History | `order_history_screen.dart` | Past orders with status tracking |
| Ledger | `ledger_screen.dart` | Financial ledger with outstanding, credits |
| Schemes | `schemes_screen.dart` | Active & past promotional schemes |
| Grievances | `grievance_screen.dart` | Submit & track complaints |

### Product Categories
- Wall Putty, Primers, Paints, Waterproofing, Textures

### Order Statuses
`Placed` → `Approved` → `Dispatched` → `Delivered` / `Cancelled`

### Ledger Entry Types
Invoice, Payment, Credit Note, Debit Note, Adjustment

### Scheme Types
Discount, Cashback, Gift, Bonus, Combo

### Grievance Flow
`Open` → `In Progress` → `Resolved` → `Closed`

---

## 3. Market Mapping (`features/market_mapping/`)

Market intelligence tools for field teams to track competitor activities.

**Service**: `MarketMappingService` · **Models**: `market_mapping_models.dart`

| Screen | File | Description |
|---|---|---|
| Market Mapping Home | `market_mapping_home_screen.dart` | Dashboard with market stats |
| Competitor Pricing | `competitor_pricing_screen.dart` | Log competitor product prices |
| New Launches | `new_launches_screen.dart` | Track competitor product launches |
| Discount Tracking | `discount_tracking_screen.dart` | Monitor competitor discounts |
| Market Intelligence | `market_intelligence_screen.dart` | Intelligence reports & insights |

---

## 4. Sales Monitoring (`features/sales_monitoring/`)

Field sales team operations management.

**Service**: `SalesMonitoringService` · **Models**: `sales_monitoring_models.dart`

| Screen | File | Description |
|---|---|---|
| Sales Monitoring Home | *(via routing)* | Dashboard |
| Counter Mapping | `counter_mapping` screen | Map sales counters |
| Visit Planning | `visit_planning` screen | Plan & schedule field visits |
| Route Tracking | `route_tracking` screen | GPS-based route tracking |

---

## 5. User Management (`features/user_management/`)

Admin functionality for managing system users.

**Service**: `UserListService` · **Models**: `user_list_models.dart`

| Screen | File | Description |
|---|---|---|
| User List | `user_list_screen.dart` | Paginated user directory |
| User Edit | `user_edit_screen.dart` | Edit user details, roles, permissions |

**Included Docs**: `README.md`, `FIELD_MAPPING.md`, `TROUBLESHOOTING.md`

---

## 6. Quality Control (`features/quality_control/`)

Quality assurance dashboards and approval workflows.

| Screen | File | Description |
|---|---|---|
| Dashboard | `dashboard.dart` | QC metrics and overview |
| Approval Dashboard | `approval_dashboard.dart` | Pending approvals queue |

---

## 7. Activity Tracking (`features/activity/`)

User activity tracking and reporting.

| Component | File | Description |
|---|---|---|
| Activity Model | `models/` | Activity data structures |
| Activity Screen | `screens/` | Activity display |
| Activity Widgets | `widgets/` | Reusable activity UI components |

---

## 8. Stock Visibility (`features/stock_visibility/`)

Inventory management for field visibility.

**Service**: `StockService` · **Models**: `stock_models.dart`

| Screen | Description |
|---|---|
| Stock Entry | Record current stock levels |
| Aging Stock | Track and report aging inventory |

---

## 9. Product Journey (`features/product_journey/`)

End-to-end product lifecycle tracking from manufacturing to delivery.

**Service**: `ProductJourneyService` · **Models**: `product_journey_models.dart`

| Screen | File | Description |
|---|---|---|
| Product Journey | `product_journey_screen.dart` | Track product through supply chain |

---

## 10. Sample Distribution (`features/sample_distribution/`)

Manage sample product distribution campaigns.

**Service**: `SampleDistributionService` · **Models**: `sample_distribution_models.dart`

| Screen | File | Description |
|---|---|---|
| Sample Distribution Entry | `sample_distribution_entry_screen.dart` | Log sample distribution |

**Included Doc**: `README.md`

---

## 11. Sample Execution (`features/sample_execution/`)

Execute and track sample collection campaigns.

**Service**: `SamplingExecutionService` · **Models**: `sampling_drive_models.dart`

| Screen | File | Description |
|---|---|---|
| Sample Execution Entry | `sample_execution_entry_screen.dart` | Record sample execution |

**Included Doc**: `README.md`

---

## 12. Retailer (`features/retailer/`)

Retailer-specific workflows.

**Service**: `RetailerOnboardingService` · **Models**: `retailer_onboarding_models.dart`

| Component | Description |
|---|---|
| Retailer Screens | `screens/` directory with retailer workflows |
