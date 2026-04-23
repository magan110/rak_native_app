# RAK App

**RAK Business Management** — Enterprise mobile application for **Ras Al Khaimah Co. for White Cement & Construction Materials (RAKWCCM)**.

> Version `24.0.0+42` · Flutter SDK `^3.8.1` · Dart 3

---

## Overview

RAK App is a multi-role Flutter application designed for RAKWCCM's business operations across the UAE. It supports **contractors, painters, retailers, trade partners, and administrators** with dedicated workflows including:

- **User Registration & KYC** — Role-based onboarding with OCR document scanning (Emirates ID, VAT certificates, bank details, commercial licences)
- **Trade Partner Journey** — Product catalogue, order placement, ledger management, schemes, and grievance handling
- **Market Mapping** — Competitor pricing, new launches, discount tracking, and market intelligence
- **Sales Monitoring** — Counter mapping, visit planning, and route tracking
- **Stock Visibility** — Stock entry and aging stock management
- **Product Journey Tracking** — End-to-end product lifecycle tracking
- **Quality Control** — Dashboard & approval workflows
- **Sample Distribution & Execution** — Sample drive management

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart 3) |
| **State Management** | StatefulWidget / Service layer pattern |
| **Routing** | [go_router](https://pub.dev/packages/go_router) `^16.2.5` |
| **Networking** | `http` package with custom SSL pinning (`SslHttpClient`) |
| **Storage** | `shared_preferences` for local persistence |
| **OCR** | Google ML Kit Text Recognition + Gemini AI fallback |
| **Responsive UI** | `flutter_screenutil` `^5.9.3` |
| **Location** | `geolocator` `^14.0.2` |
| **QR/Barcode** | `mobile_scanner` `^7.1.3` |
| **PDF** | `pdfx` (viewing) + `pdf` (generation) |
| **Image** | `image_picker`, `photo_view`, `image` |
| **Functional** | `dartz` (Either/Option), `equatable` |
| **CI/CD** | Codemagic |

---

## Prerequisites

- Flutter SDK `>=3.8.1`
- Dart SDK `>=3.0.0`
- Android Studio / Xcode
- Valid SSL certificate at `assets/cert/rak_cer.pem`

---

## Getting Started

```bash
# 1. Clone the repository
git clone <repository-url>
cd rak_native_app_22-12

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device
flutter run
```

### Environment Configuration

The app supports three environments configured in `lib/config/app_config.dart`:

| Environment | Base URL |
|---|---|
| **Development** (default) | `https://dev-api.example.com` |
| **Staging** | `https://staging-api.example.com` |
| **Production** | `https://api.example.com` |

The actual API backend is hosted at `https://qa.birlawhite.com:55232` (configured in `lib/core/constants/app_constants.dart` and `lib/core/config/api_config.dart`).

---

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # Root MaterialApp widget
├── config/                   # App configuration (environments)
├── core/                     # Shared infrastructure
│   ├── config/               # API & Gemini configuration
│   ├── constants/            # App constants & API endpoints
│   ├── debug/                # Debug screens
│   ├── errors/               # Exception & failure classes
│   ├── extensions/           # Dart extension methods
│   ├── models/               # 17 data model files
│   ├── network/              # ApiClient, SslHttpClient
│   ├── routes/               # GoRouter setup & route names
│   ├── services/             # 33+ business & infra services
│   ├── theme/                # App theme & colours
│   └── utils/                # Logger, validators, responsive utils
├── features/                 # Feature modules
│   ├── activity/             # Activity tracking
│   ├── market_mapping/       # Market intelligence
│   ├── product_journey/      # Product lifecycle tracking
│   ├── quality_control/      # QC dashboards
│   ├── retailer/             # Retailer onboarding
│   ├── sales_monitoring/     # Sales field operations
│   ├── sample_distribution/  # Sample distribution entry
│   ├── sample_execution/     # Sample execution tracking
│   ├── screens/              # Core app screens (auth, home, registration)
│   ├── stock_visibility/     # Stock management
│   ├── trade_partner_journey/# Trade partner workflows
│   └── user_management/      # Admin user CRUD
└── shared/                   # Shared widgets & presentations
    ├── presentation/         # Camera scanner, file manager, QR input
    └── widgets/              # Reusable UI components
```

---

## Documentation Index

| Document | Description |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Application architecture & design patterns |
| [FEATURES.md](FEATURES.md) | Feature modules & screen reference |
| [API_SERVICES.md](API_SERVICES.md) | Core services & API documentation |
| [MODELS.md](MODELS.md) | Data models reference |
| [ROUTING.md](ROUTING.md) | Navigation & routing guide |
| [AUTHENTICATION.md](AUTHENTICATION.md) | Authentication flow & role management |

---

## Build & Deploy

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ipa --release
```

### CI/CD

The project uses **Codemagic** for automated builds. Configuration is in `codemagic.yaml`.

---

## Company Information

- **Company**: Ras Al Khaimah Co. for White Cement & Construction Materials (RAKWCCM)
- **Short Name**: RAKWCCM
- **Website**: [rakwhitecement.ae](https://rakwhitecement.ae/)
- **Products**: White Cement, Quick Lime, Hydrated Lime, Dolomitic Lime, Concrete Blocks, Interlocks, Kerbstones
