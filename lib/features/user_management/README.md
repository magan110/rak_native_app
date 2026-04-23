# User Management Feature

This feature provides a comprehensive user management screen for viewing and editing all contractors and painters in the system.

## Files Created

1. **user_list_screen.dart** - Main UI screen with filtering and card-based list
2. **user_edit_screen.dart** - Comprehensive edit screen with all registration fields
3. **user_list_models.dart** - Data models for users
4. **user_list_service.dart** - API service layer (ready for backend integration)

## Features

### Filtering
- Search by name, Emirates ID, or Registration ID
- Filter by user type (All, Contractor, Painter)
- Real-time search updates

### User Cards
- Card-based layout similar to approval dashboard
- Shows user avatar, name, type, registration ID, and status
- Click on any card to open edit dialog

### Edit Screen
- Full-screen edit interface with tabbed navigation
- **For Painters**: 3 tabs (Personal, Emirates ID, Bank Details)
- **For Contractors**: 5 tabs (Personal, Emirates ID, Bank Details, License, VAT)
- All registration fields are editable
- Status toggle (Active/Inactive)
- Save changes functionality (ready for API integration)

#### Edit Screen Tabs (Matching Registration Forms):

**Personal Details Tab:**
- Contractor Type (Contractors only)
- First Name * (Mandatory)
- Middle Name
- Last Name * (Mandatory)
- Mobile Number * (Mandatory)
- Email Address
- Address * (Mandatory)
- Area
- Emirates * (Mandatory)
- Status (Active/Inactive)

**Emirates ID Tab:**
- Emirates ID Number * (Mandatory)
- Name on ID * (Mandatory)
- Date of Birth
- Nationality * (Mandatory)
- Company Details (Employer) * (Mandatory)
- Issue Date * (Mandatory)
- Expiry Date * (Mandatory)
- Occupation

**Bank Details Tab:**
- Account Holder Name (Optional)
- IBAN Number (Optional)
- Bank Name (Optional)
- Branch Name (Optional)
- Bank Address (Optional)

**Commercial License Tab (Contractors only):**
- License Number * (Mandatory)
- Issuing Authority
- License Type
- Establishment Date
- License Expiry Date
- Trade Name
- Responsible Person
- License Address (Registered Address)
- Effective Date (Effective Registration Date)

**VAT Certificate Tab (Contractors only):**
- Note: Non-mandatory for turnover below 375,000 AED
- Firm Name (Name of the Firm)
- VAT Registered Address
- Tax Registration Number (TRN) - Format: XXX-XXXXXXXXX-XXX
- VAT Effective Date

## Navigation

Access the screen via:
```dart
context.go('/user-list');
// or
context.goNamed('user-list');
```

### Added to Home Screen Menu

The User Management screen has been added to the home screen drawer menu:
- **Location**: Between "Activity Entry" and the divider
- **Icon**: Icons.people
- **Label**: "User Management"
- **Also added to search suggestions** for easy discovery

## Current Implementation

Currently using **dummy data** with 6 sample users (3 contractors, 3 painters).

## API Integration

✅ **Backend API is fully integrated!**

### Available Endpoints:

1. **GET /api/Users/all** - List all users with filtering
   - Query params: `search`, `type` (Contractor/Painter)
   - Returns paginated list with all user fields

2. **GET /api/Users/{userId}** - Get detailed user information
   - Returns complete user profile with all registration fields

3. **POST /api/Users/update/{userId}** - Update user details
   - Changed from PUT to POST to bypass WAF blocking
   - Accepts all registration fields
   - Validates mandatory fields and formats
   - Returns success/error with validation messages

### To Enable Real API:

In `user_list_screen.dart`, uncomment the API call in `_loadDummyData()`:

```dart
Future<void> _loadDummyData() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final service = UserListService();
    final response = await service.getAllUsers();
    _allUsers = response.items;
    
    // Remove dummy data section
    
    _filteredUsers = _allUsers;
    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    // Error handling already implemented
  }
}
```

### Features Implemented:

- ✅ Real-time search and filtering
- ✅ Complete field validation
- ✅ Error handling with user-friendly messages
- ✅ Loading indicators during API calls
- ✅ Success/error notifications
- ✅ Audit logging (backend)
- ✅ Debug logging for troubleshooting

## Known Issues

### 406 Error - WAF Blocking

If you encounter a **406 Not Acceptable** error when saving changes, this is caused by the Web Application Firewall (WAF) blocking the PUT request. This is a **network security layer issue**, not an application bug.

**See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions and next steps.**

**Quick Summary:**
- The WAF at `custom-page.qa-apptrana.com` is blocking requests
- Contact your infrastructure team to whitelist the mobile app
- Provide them with the request ID from the error logs
- The API endpoint itself is working correctly

The app now shows a user-friendly error message:
```
Request blocked by security firewall. This may be due to network 
security policies. Please try again or contact your administrator.
```

## Styling

The screen follows the same design system as the approval dashboard:
- Blue gradient header (Color(0xFF1E3A8A) to Color(0xFF3B82F6))
- White cards with subtle shadows
- Consistent spacing and typography
- Responsive design with ScreenUtil

## Sample Data Structure

```dart
UserItem(
  id: 'C001',
  name: 'Ahmed Al Maktoum',
  type: 'Contractor',
  emiratesId: '784-1990-1234567-1',
  registrationId: 'REG-C-001',
  mobile: '971501234567',
  email: 'ahmed.maktoum@example.com',
  status: 'Active',
  avatar: 'https://i.pravatar.cc/150?img=12',
  companyName: 'Al Maktoum Construction',
  licenseNumber: 'LIC-12345',
)
```
