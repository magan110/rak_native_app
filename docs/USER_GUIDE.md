# RAK App — Complete User Guide

**RAK Business Management** · Version 24.0.0 · A mobile application for Ras Al Khaimah Co. for White Cement & Construction Materials (RAKWCCM)

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
   - [Login Methods](#21-login-methods)
   - [Auto-Login](#22-auto-login)
   - [Logout](#23-logout)
3. [Home Screen & Navigation](#3-home-screen--navigation)
4. [Registration](#4-registration)
   - [Contractor Registration](#41-contractor-registration-5-steps)
   - [Painter Registration](#42-painter-registration)
   - [Retailer Registration](#43-retailer-registration-3-steps)
5. [Trade Partner Journey](#5-trade-partner-journey)
6. [Market Mapping](#6-market-mapping)
7. [Sales Monitoring](#7-sales-monitoring)
8. [Stock Visibility](#8-stock-visibility)
9. [Quality Control](#9-quality-control)
10. [Sample Distribution](#10-sample-distribution)
11. [Sample Execution](#11-sample-execution)
12. [Activity Tracking](#12-activity-tracking)
13. [Product Journey](#13-product-journey)
14. [User Management (Admin)](#14-user-management-admin)
15. [Notifications](#15-notifications)
16. [Tips & Troubleshooting](#16-tips--troubleshooting)

---

## 1. Introduction

The **RAK App** is an enterprise mobile application developed for RAKWCCM's business operations across the UAE. It serves multiple user roles — **Contractors, Painters, Retailers, Trade Partners, and Administrators** — with dedicated dashboards and workflows for each.

### Supported User Roles

| Role | Home Screen | Primary Use |
|---|---|---|
| Admin / General Staff | General Home | User management, quick actions, admin tasks |
| Contractor | Contractor Home | Registration management, KYC, business ops |
| Painter | Painter Home | Painter-specific KYC and workflows |
| Trade Partner | Trade Partner Home | Orders, ledger, schemes, grievances |

### Key Capabilities
- OCR-powered document scanning (Emirates ID, VAT certificates, bank documents)
- QR/Barcode scanning via built-in camera
- GPS-based location capture
- Offline-resilient design with local session caching
- SSL-pinned secure API communication

---

## 2. Getting Started

### 2.1 Login Methods

The app offers two ways to log in:

#### Option A — User ID & Password

1. Open the app and tap **"Login with Password"**
2. Enter your **User ID** (assigned by your administrator)
3. Enter your **Password**
4. Tap **Login**
5. The app routes you to your role-specific home screen after successful authentication

#### Option B — Mobile OTP

1. Tap **"Login with OTP"**
2. Enter your registered **UAE mobile number** (e.g., `05xxxxxxxx` or `9715xxxxxxxx`)
3. Tap **Send OTP** — a 6-digit code is delivered via SMS within seconds
4. Enter the OTP in the verification field
5. OTPs expire after **5 minutes**; tap **Resend** after a 30-second cooldown if needed
6. Tap **Verify & Login**

> **Note:** Only mobile numbers registered in the system can receive OTPs. If your number is not recognised, contact your administrator.

### 2.2 Auto-Login

When you log in successfully, the app saves a secure session on your device. On your next launch, the **Splash Screen** automatically checks for a valid session and takes you directly to your home screen — no manual login required.

To disable auto-login, use the **Logout** function instead of simply closing the app.

### 2.3 Logout

1. Open the **side drawer** (hamburger menu ☰ in the top-left)
2. Scroll to the bottom of the menu and tap **Logout**
3. Your session is cleared from both the device and the server

---

## 3. Home Screen & Navigation

After login, you are taken to your role-appropriate dashboard.

### General Home Screen

The default home for admin/general staff users contains:

| Section | Description |
|---|---|
| **Welcome Card** | Displays your name, greeting, and RAKWCCM branding |
| **Featured Products** | Auto-scrolling carousel of RAK product ranges (MBF, RWC, Construction Materials). Tap any card to view product details. |
| **Quick Actions** | Grid of shortcut tiles for the most-used features |
| **Business Metrics** | Summary of key performance data |

#### Quick Action Tiles

| Tile | Destination |
|---|---|
| Products | Product details screen |
| Admin User Edit | Admin user management |
| Sample Distribution | Sample distribution entry |
| Activity Entry | Activity logging |
| Sample Execution | Sample execution entry |
| User Management | User list / admin panel |

#### App Bar Controls

| Control | Action |
|---|---|
| ☰ (hamburger) | Opens the side navigation drawer |
| 🔍 (search) | Opens app-wide search |
| 🔔 (bell) | View your notifications (badge shows unread count) |

### Side Drawer Navigation

The drawer displays your **name**, **area code**, and a full navigation menu. Tap any item to navigate:

- Home
- Registration
- Market Mapping
- Sales Monitoring
- Stock Visibility
- Quality Control
- Sample Distribution / Execution
- Activity
- Product Journey
- Trade Partner Journey
- User Management
- Logout

### Bottom Navigation Bar

Three tabs are always accessible via the bottom bar:

| Tab | Icon | Description |
|---|---|---|
| Home | 🏠 | Main dashboard |
| Scan | 📷 | QR / Barcode scanner |
| Profile | 👤 | Your profile & settings |

---

## 4. Registration

From the **Home → Side Drawer → Registration**, or directly from the Registration Type Selection screen.

### 4.0 Choosing Your Registration Type

The **Registration Type** screen shows two cards:

| Card | Who Should Select It |
|---|---|
| **Contractor** | Businesses that hire painters or provide painting/contracting services |
| **Painter** | Individuals who work under a contractor or as independent service providers |

Tap **"Register as Contractor"** or **"Register as Painter"** to begin.  
Tap the **?** (help) icon in the top-right for guidance if unsure.

---

### 4.1 Contractor Registration (5 Steps)

A guided, multi-step form that collects all KYC and business information required for a contractor account.

#### Step 1 — Mobile Verification

| Field | Notes |
|---|---|
| Mobile Number | Enter your UAE mobile number (9 digits, no country code, e.g. `05xxxxxxxx`) |
| Send OTP | Tap to receive a 6-digit code via SMS |
| OTP Code | Enter the code within 5 minutes |
| Resend OTP | Available after 30 seconds if OTP was not received |

✅ You **must** verify your mobile with OTP before proceeding to Step 2.  
✅ If your number is already registered, the system informs you; you may log in instead.

#### Step 2 — Emirates ID Verification

Upload a clear photo or scan of your **Emirates ID** (front and back). The app uses **OCR (Optical Character Recognition)** powered by **Google ML Kit** and **Gemini AI** to automatically extract:

- Full name (First, Middle, Last)
- Emirates ID number
- Date of birth
- Nationality
- Issue and expiry dates

> **Tip:** Ensure the ID is fully visible, well-lit, and the image is not blurry. The system will auto-fill fields; review and correct them if needed.

#### Step 3 — Personal Details

| Field | Notes |
|---|---|
| First Name | Auto-filled from OCR; editable |
| Middle Name | Optional |
| Last Name | Auto-filled from OCR; editable |
| Emirates ID Number | Auto-filled from OCR |
| Date of Birth | Auto-filled; editable |
| Nationality | Auto-filled from OCR |
| Occupation | Enter your occupation |
| Address | Your residential address |
| Contractor Type | **Required** — Select from: Maintenance Contractor, Petty Contractor |
| Emirate | **Required** — Select your emirate of operation |

Profile Photo upload is optional but recommended.

#### Step 4 — Business Information

| Field | Notes |
|---|---|
| Firm / Company Name | Registered business name |
| Registered Address | Business address |
| Tax (TRN) Number | UAE Tax Registration Number |
| VAT Certificate | Upload VAT certificate image/PDF (OCR auto-extracts details) |
| Trade Licence Number | Business trade licence |
| Trade Name | Name on the licence |
| Commercial Licence | Upload licence image/PDF (OCR auto-extracts details) |
| Issuing Authority | Select the authority that issued the licence |
| Licence Type | Select the type |
| Licence Expiry Date | Taken from OCR extraction |
| Responsible Person | Person responsible for the business |
| Establishment Date | Date the business was registered |

#### Step 5 — Bank Details

| Field | Notes |
|---|---|
| Account Holder Name | Name as on bank account |
| Bank Name | Name of your bank |
| Branch Name | Branch name |
| IBAN Number | Your UAE IBAN |
| Bank Address | Branch address |
| Bank Document | Upload a cheque copy or bank statement (OCR auto-extracts details) |

Tap **"Submit Registration"** on Step 5 to complete.  
On success, you are taken to the **Success Screen** confirming your registration.

---

### 4.2 Painter Registration

Similar to Contractor Registration, the Painter flow collects:

- **Mobile Verification** (OTP)
- **Emirates ID** (with OCR scan)
- **Personal Details** (name, DOB, nationality, address)
- **Work Details** (works under a specific contractor or independently)
- **Bank Details** (IBAN, bank name, cheque copy upload)

The painter's KYC status is tracked and visible within the registration screen.

---

### 4.3 Retailer Registration (3 Steps)

Used to onboard a **retail store/outlet** that sells RAKWCCM products.

#### Process Type

At the top of Step 1, select:
- **Add** — Register a new retailer
- **Update** — Update an existing retailer's details (requires you to enter the existing Retailer Code and tap **Fetch** to pre-fill all fields)

#### Step 1 — Business Identity

| Field | Required | Notes |
|---|---|---|
| Process Type | ✅ | Add or Update |
| Retailer Code | Only for Update | Enter code and tap **Fetch** to auto-populate form |
| Firm Name | — | Registered firm/shop name |
| TRN Number | — | UAE Tax Registration Number |
| TRN Document | — | Upload image or PDF |
| Trade Licence Number | — | Business licence |
| Counter Type | ✅ | **Paint** or **Non-Paint** |
| Business Details | — | E.g., years active |
| Emirates ID | — | Retailer's Emirates ID number |

#### Step 2 — Contact & Location

| Field | Required | Notes |
|---|---|---|
| Mobile Number | ✅ | Retailer's contact number |
| Email ID | — | Retailer's email |
| Emirate | ✅ | Select from dropdown |
| District | ✅ | Auto-loaded based on emirate selection |
| Area Name | ✅ | Auto-loaded based on district selection |
| PO Box | — | Postal box number |
| Full Address | ✅ | Complete physical address |
| Latitude / Longitude | — | Auto-captured via GPS on form load; editable |
| Branch Details | — | Additional branch info |

> **GPS Auto-Capture:** The app automatically captures your current GPS coordinates when the form opens. You can manually correct them if needed.

#### Step 3 — Bank Details

| Field | Required | Notes |
|---|---|---|
| Account Holder Name | ✅ | |
| Bank Name | ✅ | |
| Account Number | ✅ | Numeric |
| IBAN Number | ✅ | UAE IBAN |
| Cheque Copy | — | Upload JPG, PNG, or PDF |

Tap **Submit** on Step 3 to complete. Documents (TRN, cheque) are uploaded automatically after successful data submission.

---

## 5. Trade Partner Journey

Accessible from the **Trade Partner Home** screen (for users with the Trade Partner role).

### 5.1 Product Catalogue

Browse RAKWCCM's complete product range:
- Categories: Wall Putty, Primers, Paints, Waterproofing, Textures
- Tap a product to view full details, pricing, and availability
- Products are organised by category for easy browsing

### 5.2 Place Order

1. Navigate to **Place Order** from the Trade Partner Home
2. Browse the product catalogue and add items to your cart
3. Specify quantities for each item
4. Review your cart and confirm the order
5. Tap **Submit Order** to place

#### Order Status Lifecycle

```
Placed → Approved → Dispatched → Delivered
                              ↘ Cancelled
```

### 5.3 Order History

View all past and current orders:
- Filter by status: Placed, Approved, Dispatched, Delivered, Cancelled
- Tap any order to see full details and line items

### 5.4 Ledger

Your financial ledger shows all transactions with RAKWCCM:

| Entry Type | Description |
|---|---|
| Invoice | Amount billed for products |
| Payment | Payments made to RAKWCCM |
| Credit Note | Credits applied to your account |
| Debit Note | Debit adjustments |
| Adjustment | Miscellaneous adjustments |

- View outstanding balance, credits, and net payable
- Entries are listed chronologically with dates and amounts

### 5.5 Schemes

View all promotional schemes available to you:

| Scheme Type | Description |
|---|---|
| Discount | Percentage off on specific products |
| Cashback | Cashback amount on purchases |
| Gift | Free gifts on reaching targets |
| Bonus | Bonus credits |
| Combo | Multi-product bundle deals |

- **Active** tab: Currently running schemes
- **Past** tab: Expired/historical schemes

### 5.6 Grievances

Log and track complaints or issues:

1. Tap **New Grievance**
2. Select the grievance category and fill in the description
3. Submit

#### Grievance Status Flow

```
Open → In Progress → Resolved → Closed
```

Track the resolution status of each grievance from the Grievances list screen.

---

## 6. Market Mapping

For **field team users** to track competitive intelligence.

### 6.1 Competitor Pricing

- Log competitor product prices at specific retail counters
- Select the competitor brand, product, and enter the observed price
- GPS location is captured automatically

### 6.2 New Launches

Record newly launched competitor products:
- Competitor brand name
- Product name and description
- Launch date and location

### 6.3 Discount Tracking

Capture competitor discount and promotional offers:
- Enter discount percentage or value
- Link to a specific product and retailer

### 6.4 Market Intelligence

View aggregated market intelligence reports:
- Competitor pricing trends
- Discount activity
- Market share indicators

---

## 7. Sales Monitoring

For **field sales representatives** to manage their daily activities.

### 7.1 Counter Mapping

Map retail counters/outlets in your territory:
- Search for existing counters or add new ones
- Capture location, outlet type, and contact details

### 7.2 Visit Planning

Plan scheduled visits to outlets:
- Select the outlet from your counter list
- Set the visit date and purpose
- Assign priority

### 7.3 Route Tracking

GPS-based route tracking during field visits:
- The app records your travel path in real time
- Visited counters are marked on the route
- Trip summary shows distance covered and stops made

---

## 8. Stock Visibility

Manage and track inventory in the field.

### 8.1 Stock Entry

Record current stock levels at a retail counter:
- Select the counter/outlet
- For each product SKU, enter the current stock quantity
- Submit to sync with the backend

### 8.2 Aging Stock

Track products that have been sitting in inventory for extended periods:
- View aging stock report per outlet
- Enter aging stock quantities per SKU
- Flag slow-moving items for management review

---

## 9. Quality Control

Dashboards and workflows for the QC team.

### 9.1 QC Dashboard

- View a summary of quality checks completed vs. pending
- KPIs: Pass rate, Fail rate, Pending reviews

### 9.2 Approval Dashboard

Approve or reject pending quality control submissions:
- View submission details (product batch, submitter, date)
- Tap **Approve** or **Reject** with remarks

---

## 10. Sample Distribution

Manage outbound product sample campaigns.

### Sample Distribution Entry

Record each sample distribution event:
1. Select the **outlet/counter** receiving samples
2. Select the **products** and quantities distributed
3. Capture GPS location (auto-captured)
4. Add any remarks
5. Submit

All past distribution events are logged and accessible for reporting.

---

## 11. Sample Execution

Track the execution (follow-up) of sample campaigns.

### Sample Execution Entry

After a sample has been distributed, record execution feedback:
1. Select the related distribution event
2. Select the outlet
3. Enter execution details (installation, application, feedback)
4. Upload photos if required
5. Submit

This creates an end-to-end record linking sample distribution to actual usage.

---

## 12. Activity Tracking

Log your daily field activities.

### Activity Entry

Record any field activity or visit:
- Activity type (customer visit, retailer call, etc.)
- Location (GPS auto-captured)
- Notes and remarks
- Date and time (defaulted to current time)

Activities are aggregated for reporting and performance review by managers.

---

## 13. Product Journey

Track product lifecycle from manufacturing to delivery.

### Product Journey Screen

- Enter a **product batch number** or scan a **QR/barcode**
- View the complete journey of that product:
  - Manufacturing date and batch
  - Dispatch date and vehicle
  - Current location and status
  - Delivery confirmation

---

## 14. User Management (Admin)

Available to administrators.

### User List

- View all registered users in the system with search and filter
- Paginated list showing name, role, area, and status

### User Edit

Edit a selected user's details:
- Name, contact information
- Role assignments
- Area code / territory
- Enable or disable the account

---

## 15. Notifications

Accessible from the 🔔 icon in the app bar (shows unread count badge).

- View all system notifications in reverse chronological order
- Tap a notification to navigate to the relevant screen
- Notifications may include: order status updates, scheme announcements, KYC alerts, and admin messages

---

## 16. Tips & Troubleshooting

### OCR Tips

| Issue | Solution |
|---|---|
| OCR did not read the document correctly | Ensure good lighting and the full document is in frame. Retake the photo. |
| Fields not auto-filled after upload | Wait for the processing spinner to finish. If blank, fill in manually. |
| OCR result is partially wrong | Always review auto-filled fields and correct where needed before proceeding. |

### OTP Issues

| Issue | Solution |
|---|---|
| OTP not received | Check your mobile signal. Wait 30 seconds and tap **Resend OTP**. |
| OTP expired | OTPs are valid for 5 minutes. Request a new one after the cooldown. |
| Wrong mobile number entered | Go back and re-enter the correct mobile number. |

### Login Issues

| Issue | Solution |
|---|---|
| Incorrect User ID or Password | Double-check credentials. Contact your admin if forgotten. |
| Auto-login fails on restart | Tap **Login** manually. If persistent, check your internet connection. |
| Session expired | Log in again. The app securely clears expired sessions. |

### Location / GPS Issues

| Issue | Solution |
|---|---|
| GPS not capturing location | Grant the app **Location permission** in your phone's settings. |
| Inaccurate coordinates | Wait for GPS to stabilise, then tap **Refresh Location** if available. |

### File Upload Issues

| Issue | Solution |
|---|---|
| File not uploading | Ensure the file is JPG, PNG, or PDF and within the size limit. |
| Upload stuck | Check your internet connection and try again. |

### General

- **Always use the latest version** of the app for the best experience and latest features.
- **Internet connection is required** for all data submission and fetching operations.
- For technical issues not covered here, contact your RAKWCCM system administrator.

---

## Company Information

| | |
|---|---|
| **Company** | Ras Al Khaimah Co. for White Cement & Construction Materials |
| **Short Name** | RAKWCCM |
| **Website** | [rakwhitecement.ae](https://rakwhitecement.ae/) |
| **Products** | White Cement, Quick Lime, Hydrated Lime, Dolomitic Lime, Concrete Blocks, Interlocks, Kerbstones |

---

*Document version: 24.0.0 · Generated: March 2026*
