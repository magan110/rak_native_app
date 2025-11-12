# Codemagic Setup Guide - RAK Circle iOS Build

## Quick Start Checklist

- [ ] Sign up at https://codemagic.io/signup
- [ ] Connect your Git repository
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create app in App Store Connect
- [ ] Set up code signing in Codemagic
- [ ] Create App Store Connect API key
- [ ] Update email in codemagic.yaml
- [ ] Push to Git and build!

## Step 1: Sign Up for Codemagic (5 minutes)

1. Go to https://codemagic.io/signup
2. Sign up with GitHub/GitLab/Bitbucket
3. Free tier: 500 build minutes/month

## Step 2: Connect Repository (2 minutes)

1. Click "Add application"
2. Select your Git provider
3. Choose your rak_app repository
4. Click "Finish: Add application"

## Step 3: Apple Developer Account (Required)

**Cost: $99/year**

1. Go to https://developer.apple.com/programs/
2. Enroll in Apple Developer Program
3. Wait 24-48 hours for approval

## Step 4: Create App in App Store Connect (5 minutes)

1. Go to https://appstoreconnect.apple.com/
2. My Apps → + → New App
3. Fill in:
   - Platform: iOS
   - Name: RAK Circle
   - Bundle ID: com.example.rakApp
   - SKU: rakcircle
4. Click Create

## Step 5: Automatic Code Signing (10 minutes)

**This is the easiest way - Codemagic does everything!**

1. In Codemagic → Your app → Distribution → iOS code signing
2. Click "Enable automatic code signing"
3. Click "Connect Apple Developer Portal"
4. Sign in with your Apple ID
5. Done! Codemagic handles certificates and profiles

## Step 6: App Store Connect API Key (10 minutes)

### Create API Key:
1. Go to https://appstoreconnect.apple.com/access/api
2. Click "+" to create new key
3. Name: "Codemagic"
4. Access: Admin or App Manager
5. Click Generate
6. **Download .p8 file** (only chance!)
7. Note: Issuer ID and Key ID

### Add to Codemagic:
1. Codemagic → Teams → Integrations
2. Click "App Store Connect"
3. Enter Issuer ID, Key ID
4. Upload .p8 file
5. Save

## Step 7: Update Email (1 minute)

Edit `codemagic.yaml`:
```yaml
email:
  recipients:
    - your-email@example.com  # ← Change this
```

## Step 8: Push and Build (2 minutes)

```bash
git add .
git commit -m "Add Codemagic config"
git push
```

In Codemagic:
1. Click "Start new build"
2. Select branch: main
3. Select workflow: ios-release
4. Click "Start new build"

## Build Time: 10-20 minutes

Watch the logs. When done:
- Download .ipa from Artifacts
- Or test via TestFlight (auto-uploaded)

## Common Issues

### "No code signing certificates"
→ Complete Step 5 (automatic signing)

### "Bundle ID doesn't match"
→ Make sure bundle ID matches in App Store Connect

### "API authentication failed"
→ Re-check Issuer ID, Key ID, and .p8 file

## What Happens During Build

1. Codemagic spins up a Mac
2. Installs Flutter and dependencies
3. Runs `flutter build ipa`
4. Signs with your certificates
5. Creates .ipa file
6. Uploads to TestFlight
7. Emails you the result

## Cost Summary

- Apple Developer: $99/year (required)
- Codemagic: FREE (500 min/month)
- Each build: ~15 minutes
- Free tier: ~30 builds/month

## After First Build

1. Test on TestFlight
2. Add screenshots to App Store Connect
3. Write app description
4. Submit for review

## Need Help?

- Codemagic Docs: https://docs.codemagic.io/
- Support: support@codemagic.io

You're all set! 🚀
