# 🗺️ RAK Paint App - Navigation Routes Map

```
┌─────────────────────────────────────────────────────────────────┐
│                         RAK Paint App                           │
│                      Navigation Structure                        │
└─────────────────────────────────────────────────────────────────┘

                            START
                              │
                              ▼
                      ┌───────────────┐
                      │   /splash     │
                      │ SplashScreen  │
                      └───────┬───────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
        ┌───────────────┐           ┌───────────────┐
        │ /login-otp    │           │/login-password│
        │ LoginWithOtp  │           │LoginWithPwd   │
        └───────┬───────┘           └───────┬───────┘
                │                           │
                └─────────────┬─────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ /registration-  │
                    │     type        │
                    │  SelectRole     │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
    ┌─────────┐      ┌─────────────┐    ┌──────────┐
    │/painter │      │/contractor  │    │ /retail- │
    │ Painter │      │Contractor   │    │onboarding│
    │  Reg    │      │    Reg      │    │ Retailer │
    └────┬────┘      └──────┬──────┘    └────┬─────┘
         │                  │                 │
         └────────┬─────────┴────────┬────────┘
                  │                  │
                  ▼                  │
         ┌────────────────┐          │
         │/details/:id    │          │
         │   Details      │          │
         └────────┬───────┘          │
                  │                  │
                  ▼                  │
         ┌────────────────┐          │
         │   /success     │          │
         │   Success      │          │
         └────────┬───────┘          │
                  │                  │
                  └─────────┬────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │    /home      │
                    │  HomeScreen   │ ◄─── Main Hub
                    └───────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  PRODUCTS    │    │QUALITY CONTROL│   │   ACTIVITY   │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       ├─► /new-entry      ├─► /qc-approval    └─► /activity-entry
       ├─► /sample-dist    └─► /qc-dashboard
       ├─► /sampling-drive
       └─► /incentive-scheme

        ┌─────────────────────────────┐
        │         SHARED/COMMON        │
        └─────────────┬────────────────┘
                      │
                      ├─► /file-manager
                      ├─► /camera-scanner
                      ├─► /qr-input
                      └─► /contact-us


═══════════════════════════════════════════════════════════

📍 Route Types:

🔵 Authentication Routes (Public)
   /splash, /login-otp, /login-password

🟢 Registration Routes (Public)
   /registration-type, /registration/painter, 
   /registration/contractor, /registration/details/:id,
   /registration/success, /retail-onboarding

🟡 Protected Routes (Require Auth)*
   /home, /products/*, /qc-*, /activity-entry

🟣 Utility Routes (Mixed)
   /file-manager, /camera-scanner, /qr-input, /contact-us

* Currently disabled - implement _handleRedirect to enable

═══════════════════════════════════════════════════════════

📊 Navigation Statistics:

Total Routes:        22
Auth Routes:         3
Registration:        7
Product Routes:      4
QC Routes:          2
Activity Routes:     1
Support Routes:      1
Shared Routes:       4

═══════════════════════════════════════════════════════════

🔗 Special Features:

✅ Path Parameters:     /registration/details/:id
✅ Query Parameters:    /home?newRegistration=true&role=painter
✅ Named Routes:        All routes have names
✅ Error Handling:      Custom 404 page
✅ Auth Guards:         Ready (commented, easy to enable)
✅ Reactive Nav:        ValueNotifier integration

═══════════════════════════════════════════════════════════

📱 Common Navigation Patterns:

1. Login Flow:
   Splash → Login → Home

2. Registration Flow:
   Splash → Type → Painter/Contractor → Details → Success → Home

3. Retail Onboarding:
   Type → Onboarding → Home

4. Product Management:
   Home → Products → [New/Sample/Drive/Incentive]

5. Quality Control:
   Home → QC → [Approval/Dashboard]

6. Utilities:
   Any Screen → [File Manager/Scanner/QR Input/Contact]

═══════════════════════════════════════════════════════════
```
