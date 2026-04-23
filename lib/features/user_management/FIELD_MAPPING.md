# User Edit Screen - Field Mapping

This document shows the exact mapping between the registration forms and the edit screen fields.

## Contractor Registration Fields

### Personal Details (Tab 1)
| Field Name | Controller | Mandatory | Notes |
|------------|-----------|-----------|-------|
| Contractor Type | `_contractorTypeController` | No | Type of contractor |
| First Name | `_firstNameController` | Yes | |
| Middle Name | `_middleNameController` | No | |
| Last Name | `_lastNameController` | Yes | |
| Mobile Number | `_mobileController` | Yes | 9-digit UAE format |
| Email Address | `_emailController` | No | |
| Address | `_addressController` | Yes | Address-1 |
| Area | `_areaController` | No | Area code from emirates |
| Emirates | `_emiratesController` | Yes | |
| Profile Photo | N/A | No | Upload/Click (not editable in form) |
| Password | N/A | No | Not shown in edit |

### Emirates ID Details (Tab 2)
| Field Name | Controller | Mandatory | Notes |
|------------|-----------|-----------|-------|
| Emirates ID Number | `_emiratesIdController` | Yes | |
| Name on ID | `_idNameController` | Yes | ID Holder name |
| Date of Birth | `_dateOfBirthController` | No | |
| Nationality | `_nationalityController` | Yes | |
| Company Details | `_companyDetailsController` | Yes | Employer |
| Issue Date | `_issueDateController` | Yes | |
| Expiry Date | `_expiryDateController` | Yes | |
| Occupation | `_occupationController` | No | |

### Bank Details (Tab 3)
| Field Name | Controller | Mandatory | Notes |
|------------|-----------|-----------|-------|
| Account Holder Name | `_accountHolderController` | No | Optional in user management |
| IBAN Number | `_ibanController` | No | Optional in user management |
| Bank Name | `_bankNameController` | No | Optional in user management |
| Branch Name | `_branchNameController` | No | Optional in user management |
| Bank Address | `_bankAddressController` | No | |
| Bank Document | N/A | No | Upload (not editable in form) |

### Commercial License (Tab 4 - Contractors Only)
| Field Name | Controller | Mandatory | Notes |
|------------|-----------|-----------|-------|
| License Document | N/A | Yes | Upload (not editable in form) |
| License Number | `_licenseNumberController` | Yes | |
| Issuing Authority | `_issuingAuthorityController` | No | |
| License Type | `_licenseTypeController` | No | |
| Establishment Date | `_establishmentDateController` | No | |
| License Expiry Date | `_licenseExpiryDateController` | No | |
| Trade Name | `_tradeNameController` | No | |
| Responsible Person | `_responsiblePersonController` | No | |
| License Address | `_licenseAddressController` | No | Registered Address |
| Effective Date | `_effectiveDateController` | No | Effective Registration Date |

### VAT Certificate (Tab 5 - Contractors Only)
| Field Name | Controller | Mandatory | Notes |
|------------|-----------|-----------|-------|
| VAT Certificate | N/A | No | Upload (not editable in form) |
| Firm Name | `_firmNameController` | No | Name of the Firm |
| VAT Address | `_vatAddressController` | No | Registered Address |
| Tax Registration Number | `_taxRegistrationController` | No | XXX-XXXXXXXXX-XXX (15 digits) |
| VAT Effective Date | `_vatEffectiveDateController` | No | Effective Registration Date |

**Note:** VAT Certificate is non-mandatory for turnover below 375,000 AED

## Painter Registration Fields

Painters use the same structure but only have 3 tabs:
1. **Personal Details** - Same as contractors (without Contractor Type field)
2. **Emirates ID Details** - Same as contractors
3. **Bank Details** - Same as contractors

## Additional Fields

### Status
- Active / Inactive toggle
- Shown in Personal Details tab

## Document Uploads (Not Editable in Form)

The following fields are document uploads and are not shown as editable text fields:
- Profile Photo
- Contractor Certificate (Contractors only)
- Bank Document
- License Document (Contractors only)
- VAT Certificate (Contractors only)

These would need separate upload functionality if editing is required.

## API Integration Notes

When implementing the save functionality, map the controllers to the API request model:

```dart
ContractorRegistrationRequest(
  contractorType: _contractorTypeController.text,
  firstName: _firstNameController.text,
  middleName: _middleNameController.text,
  lastName: _lastNameController.text,
  mobileNumber: _mobileController.text,
  address: _addressController.text,
  area: _areaController.text,
  emirates: _emiratesController.text,
  emiratesIdNumber: _emiratesIdController.text,
  idName: _idNameController.text,
  dateOfBirth: _dateOfBirthController.text,
  nationality: _nationalityController.text,
  companyDetails: _companyDetailsController.text,
  issueDate: _issueDateController.text,
  expiryDate: _expiryDateController.text,
  occupation: _occupationController.text,
  accountHolderName: _accountHolderController.text,
  ibanNumber: _ibanController.text,
  bankName: _bankNameController.text,
  branchName: _branchNameController.text,
  bankAddress: _bankAddressController.text,
  licenseNumber: _licenseNumberController.text,
  issuingAuthority: _issuingAuthorityController.text,
  licenseType: _licenseTypeController.text,
  establishmentDate: _establishmentDateController.text,
  licenseExpiryDate: _licenseExpiryDateController.text,
  tradeName: _tradeNameController.text,
  responsiblePerson: _responsiblePersonController.text,
  licenseAddress: _licenseAddressController.text,
  effectiveDate: _effectiveDateController.text,
  firmName: _firmNameController.text,
  vatAddress: _vatAddressController.text,
  taxRegistrationNumber: _taxRegistrationController.text,
  vatEffectiveDate: _vatEffectiveDateController.text,
);
```
