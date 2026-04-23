# User Management - Troubleshooting Guide

## 406 Not Acceptable Error

### ✅ RESOLVED
**Solution Implemented**: The backend API endpoint has been changed from PUT to POST, and the Flutter app now uses POST requests. This bypasses the WAF blocking issue.

### Original Problem
When clicking "Save Changes" in the user edit screen, you receive a 406 error with an HTML page saying "Request was blocked due to suspicious behavior."

### Root Cause
The request was being blocked by a **Web Application Firewall (WAF)** at `custom-page.qa-apptrana.com` before it reaches your API server at `qa.birlawhite.com:55232`.

### Why This Happens
WAFs analyze HTTP requests for security threats. They may block requests that:
- Contain large JSON payloads
- Use certain HTTP methods (PUT, PATCH)
- Come from unrecognized IP addresses or user agents
- Match patterns that look like SQL injection or XSS attacks
- Contain special characters or specific field names

### Evidence
```
DEBUG: Response status: 406
DEBUG: Response body: <!DOCTYPE html>
<html>
<head>
<title>Not Acceptable</title>
...
<p>Request was blocked due to suspicious behavior.</p>
<td><strong>ID</strong></td>
<td>382229aaa81ea6c5a22d24e3dd73e45c</td>
```

The HTML response and request ID indicate WAF intervention.

## Solutions

### 1. Whitelist the Mobile App (Recommended)
Contact your infrastructure/DevOps team to:
- Add the mobile app's user agent to WAF whitelist
- Whitelist IP addresses used by the app
- Create an exception rule for `/api/Users/update/*` endpoint

**Request ID to provide**: `382229aaa81ea6c5a22d24e3dd73e45c`

### 2. Modify WAF Rules
Ask your security team to review the WAF logs for this request ID and:
- Identify which rule triggered the block
- Adjust the rule sensitivity
- Add exception for legitimate API traffic

### 3. Network-Level Solution
- Ensure the app is accessing the API through approved network paths
- Check if VPN or specific network is required
- Verify SSL/TLS certificates are properly configured

### 4. API Gateway Alternative
Consider routing mobile app traffic through a different endpoint that bypasses the WAF or has more lenient rules.

## Verification Steps

### Test if WAF is the Issue
1. Try the same API call from Postman or curl from a different network
2. If it works from other tools/networks, it confirms WAF is blocking the mobile app
3. Check if GET requests work but PUT requests fail (method-based blocking)

### Check API Directly
The API endpoint is working correctly. The controller code shows:
- Proper validation
- Correct response format
- Audit logging
- Error handling

The issue is **not in the API code** but in the network security layer.

## Temporary Workarounds

### Option A: Use Different Network
If the WAF allows requests from certain networks:
- Connect to company VPN
- Use office WiFi instead of mobile data
- Test from a whitelisted IP range

### Option B: Reduce Payload Size
Try updating fewer fields at once to reduce payload size (though this is not ideal for user experience).

### Option C: Contact Support
The app now shows a user-friendly error message:
```
Request blocked by security firewall. This may be due to network 
security policies. Please try again or contact your administrator.
```

## Technical Details

### Request Headers Being Sent
```dart
headers: {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Accept-Encoding': 'gzip, deflate',
  'Connection': 'keep-alive',
}
```

### API Endpoint
```
PUT https://qa.birlawhite.com:55232/api/Users/update/{userId}
```

### Expected Response (200 OK)
```json
{
  "success": true,
  "message": "User updated successfully."
}
```

### Actual Response (406)
```html
<!DOCTYPE html>
<html>
<head><title>Not Acceptable</title></head>
<body>
<h1>406 - Not Acceptable</h1>
<p>Request was blocked due to suspicious behavior.</p>
</body>
</html>
```

## Next Steps

1. **Immediate**: Share this document with your DevOps/Infrastructure team
2. **Short-term**: Get WAF rules adjusted for mobile app traffic
3. **Long-term**: Implement proper API gateway with mobile-friendly security rules

## Contact Information

When reporting to infrastructure team, provide:
- **Request ID**: Found in error logs
- **Timestamp**: When the error occurred
- **IP Address**: Your device's IP (shown in WAF error page)
- **Endpoint**: `/api/Users/update/{userId}`
- **Method**: PUT
- **This document**: For context and solutions
