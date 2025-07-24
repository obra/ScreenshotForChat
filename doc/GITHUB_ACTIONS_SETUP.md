# GitHub Actions Setup for Automated Build & Release

This document explains how to set up the required secrets for automated macOS app building and code signing.

## Required GitHub Secrets

Go to your repository Settings → Secrets and variables → Actions, and add these secrets:

### 1. Developer ID Application Certificate
- **Secret Name**: `DEVELOPER_ID_APPLICATION`
- **Value**: Base64-encoded .p12 certificate file
- **How to get it**:
  ```bash
  # Export from Keychain Access as .p12, then encode:
  base64 -i DeveloperID_Application.p12 | pbcopy
  ```

### 2. Developer ID Application Certificate Password
- **Secret Name**: `DEVELOPER_ID_APPLICATION_PASSWORD`
- **Value**: Password you set when exporting the .p12 file

### 3. Developer ID Installer Certificate (for DMG signing)
- **Secret Name**: `DEVELOPER_ID_INSTALLER` 
- **Value**: Base64-encoded .p12 certificate file
- **How to get it**:
  ```bash
  # Export installer certificate from Keychain Access as .p12
  base64 -i DeveloperID_Installer.p12 | pbcopy
  ```

### 4. Developer ID Installer Certificate Password
- **Secret Name**: `DEVELOPER_ID_INSTALLER_PASSWORD`
- **Value**: Password you set when exporting the installer .p12 file

### 5. Developer ID Name (for codesign)
- **Secret Name**: `DEVELOPER_ID_NAME`
- **Value**: Full name of your Developer ID certificate
- **Example**: `"Developer ID Application: Jesse Vincent (TEAM12345)"`
- **How to find it**:
  ```bash
  security find-identity -v -p codesigning
  ```

### 6. Apple ID (for notarization)
- **Secret Name**: `APPLE_ID`
- **Value**: Your Apple ID email address

### 7. Apple ID App-Specific Password
- **Secret Name**: `APPLE_ID_PASSWORD`
- **Value**: App-specific password (not your regular Apple ID password)
- **How to create**: https://support.apple.com/en-us/HT204397

### 8. Apple Team ID
- **Secret Name**: `APPLE_TEAM_ID`
- **Value**: Your Apple Developer Team ID (10-character string)
- **How to find it**: https://developer.apple.com/account → Membership

## How to Use

### Automatic Release (Recommended)
1. Create and push a git tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. GitHub Actions will automatically build, sign, notarize, and create a release

### Manual Build
1. Go to Actions tab in your GitHub repository
2. Select "Build and Release macOS App" workflow
3. Click "Run workflow"
4. Enter version number
5. Click "Run workflow"

## What the Workflow Does

1. **Builds** the Swift package for both ARM64 and x86_64
2. **Creates** proper macOS app bundle structure
3. **Signs** the app with your Developer ID certificate
4. **Creates** a DMG installer with nice layout
5. **Signs** the DMG
6. **Notarizes** with Apple for Gatekeeper compatibility
7. **Uploads** artifacts and creates GitHub release

## Security Notes

- All certificates are stored as encrypted GitHub secrets
- Temporary keychain is created and destroyed for each build
- No sensitive data is logged in build output
- Only specific tools are granted keychain access

## Troubleshooting

### Common Issues:
- **"No identity found"**: Check certificate names and passwords
- **"User interaction is not allowed"**: Keychain permissions issue
- **"Notarization failed"**: Check Apple ID credentials and team ID
- **"Stapler failed"**: Normal for development builds, only affects distribution

### Debug Commands:
```bash
# List available signing identities
security find-identity -v -p codesigning

# Verify app signature
codesign --verify --verbose ScreenshotForChat.app
spctl --assess --verbose ScreenshotForChat.app

# Check notarization status
xcrun notarytool history --apple-id YOUR_APPLE_ID --password YOUR_APP_PASSWORD --team-id YOUR_TEAM_ID
```