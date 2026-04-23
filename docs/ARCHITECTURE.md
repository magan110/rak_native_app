# Architecture

## High-Level Architecture

RAK App follows a **layered modular architecture** with a clear separation between core infrastructure, feature modules, and shared components.

```
┌──────────────────────────────────────────────────┐
│                    App Layer                     │
│           main.dart → app.dart                   │
├──────────────────────────────────────────────────┤
│              Feature Modules                     │
│  screens · trade_partner · market_mapping · ...  │
├──────────────────────────────────────────────────┤
│                 Shared Layer                     │
│         widgets · presentation pages             │
├──────────────────────────────────────────────────┤
│                  Core Layer                      │
│  services · models · network · routes · theme    │
├──────────────────────────────────────────────────┤
│             Flutter Framework                    │
└──────────────────────────────────────────────────┘
```

---

## Layer Details

### 1. App Layer (`lib/main.dart`, `lib/app.dart`)

- **`main.dart`** — Entry point. Initializes Flutter bindings, sets orientation & system UI style, requests location permissions, and wraps the app in `ScreenUtilInit` (iPhone 11 Pro design size: 375×812).
- **`app.dart`** — Root `MaterialApp.router` widget. Forces light theme and uses `GoRouter` for navigation.

### 2. Core Layer (`lib/core/`)

The core layer provides cross-cutting infrastructure used by all features:

| Directory | Purpose |
|---|---|
| `config/` | API base URL, Gemini AI config, timeouts, OTP settings |
| `constants/` | App constants (company info, product types, registration types), API endpoints |
| `debug/` | API debug screen for development testing |
| `errors/` | Custom exception classes (`NetworkException`, `AuthenticationException`, `ServerException`) and failure abstractions |
| `extensions/` | Dart extensions on `BuildContext` and `String` |
| `models/` | 17 data model files covering auth, profiles, orders, stock, etc. |
| `network/` | `ApiClient` (HTTP CRUD with JSON handling), `SslHttpClient` (SSL certificate pinning), `NetworkInfo` |
| `routes/` | `AppRouter` (GoRouter configuration with 40+ routes), `RouteNames` (string constants) |
| `services/` | 33+ service classes covering auth, OCR, storage, trade partners, market mapping, etc. |
| `theme/` | `AppTheme` (Material 3 light/dark themes), `AppColors`, custom `ThemeData` configurations |
| `utils/` | `Logger` (debug logging utility), `Validators` (form validation), `ResponsiveUtils` (adaptive layout helpers) |

### 3. Feature Modules (`lib/features/`)

Each feature module is self-contained with its own screens (and sometimes models/widgets):

| Module | Structure | Purpose |
|---|---|---|
| `screens/` | `data/` · `domain/` · `presentation/pages/` | Core app screens (splash, login, home, registration) |
| `trade_partner_journey/` | `presentation/screens/` · `presentation/widgets/` | Order management, ledger, schemes, grievances |
| `market_mapping/` | `presentation/screens/` | Competitor pricing, new launches, discounts, intelligence |
| `sales_monitoring/` | `presentation/screens/` | Counter mapping, visit planning, route tracking |
| `user_management/` | Flat structure with models, screens, service | Admin user list and edit |
| `quality_control/` | Flat structure | Approval dashboard, QC dashboard |
| `activity/` | `models/` · `screens/` · `widgets/` | Activity tracking |
| `stock_visibility/` | `presentation/screens/` | Stock entry, aging stock |
| `product_journey/` | `presentation/screens/` | Product lifecycle tracking |
| `sample_distribution/` | Flat structure | Sample distribution entry |
| `sample_execution/` | Flat structure | Sample execution tracking |
| `retailer/` | `screens/` | Retailer-specific flows |

### 4. Shared Layer (`lib/shared/`)

Reusable components shared across features:

| Component | Description |
|---|---|
| `widgets/file_upload_widget.dart` | Full-featured file upload with preview (76 KB) |
| `widgets/document_viewer_widget.dart` | PDF/image document viewer |
| `widgets/responsive_widgets.dart` | Responsive layout wrappers |
| `widgets/kyc_status_widget.dart` | KYC verification status display |
| `widgets/user_search_widget.dart` | User search with filtering |
| `widgets/modern_dropdown.dart` | Styled dropdown component |
| `widgets/congratulations_dialog.dart` | Success dialog with animations |
| `widgets/maintenance_dialog.dart` | Maintenance mode dialog |
| `widgets/combined_logo_widget.dart` | Company branding logos |
| `presentation/pages/camera_scanner_screen.dart` | QR/barcode camera scanner |
| `presentation/pages/file_manager_screen.dart` | File browsing & management |
| `presentation/pages/qr_input_screen.dart` | Manual QR code input |

---

## Design Patterns

### Service Layer Pattern
Business logic is encapsulated in service classes (e.g., `AuthService`, `TradePartnerService`) that handle API communication, data transformation, and business rules. Services are instantiated as needed rather than using dependency injection.

### SSL Certificate Pinning
All API communication goes through `SslHttpClient`, which loads a PEM certificate from `assets/cert/rak_cer.pem` and pins connections to the `birlawhite.com` domain. A three-tier fallback ensures connectivity:
1. SSL with bundled certificate
2. Permissive SSL with domain whitelisting
3. Default HTTP client (last resort)

### Role-Based Access Control
The `AuthManager` singleton manages the current user session and provides role/page-based access checks via `hasRole()`, `hasPage()`, `hasAnyRole()`, and `hasAnyPage()`. The `AppRouter` evaluates roles to redirect users to the correct home screen (Contractor, Painter, Trade Partner, or generic Home).

### OCR Processing Pipeline
Document scanning uses a layered approach:
1. **Google ML Kit** — On-device text recognition (primary)
2. **Gemini AI** — Cloud-based OCR via Gemini API (fallback)
3. **Hybrid Service** — Combines both for optimal results
4. **Specialized parsers** — Emirates ID, bank details, VAT certificate, and commercial licence extractors

### Responsive Design
- `flutter_screenutil` for density-independent sizing
- Custom `ResponsiveUtils` class for adaptive layouts across phone/tablet/desktop
- `ResponsiveWidgets` in shared layer for common responsive patterns

---

## Dependency Flow

```
Features ──────► Core Services ──────► Core Network (ApiClient + SSL)
    │                  │                        │
    │                  ▼                        ▼
    │            Core Models              External APIs
    │                                  (qa.birlawhite.com)
    ▼
Shared Widgets
```

- **Features** depend on **Core** (services, models, routes) and **Shared** (widgets)
- **Core Services** depend on **Core Network** and **Core Models**
- **Shared** has no dependencies on Features
- **Core** has no dependencies on Features or Shared
