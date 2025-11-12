// Filename: VERIFY_ONBOARDING_DEPLOYMENT.md
// Purpose: Checklist and verification guide for onboarding service deployment
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-30
// Dependencies: None
// Platform Compatibility: All

# Onboarding Service Deployment Verification

## Overview

The onboarding service (`infinitum-onboarding`) is a **separate Firebase project** from the down detector. This document outlines what needs to be deployed in the onboarding project for it to work correctly.

---

## Required Deployments in Onboarding Project

### 1. Firebase Cloud Functions

**Required Functions:**
- ✅ `healthCheck` - Health check endpoint (required for monitoring)
- ✅ `openapi` - OpenAPI documentation endpoint (optional but recommended)
- ✅ `enhancedSignup` - User signup
- ✅ `enhancedSignin` - User signin
- ✅ `enhancedPasswordReset` - Password reset
- ✅ `validateSession` - Session validation
- ✅ `refreshSession` - Session refresh
- ✅ `invalidateSession` - Session invalidation
- ✅ `onInviteRedeemed` - Invite redemption trigger
- ✅ `discordOAuthCallback` - Discord OAuth callback
- ✅ `discordRoleSync` - Discord role synchronization
- ✅ `fetchDiscordCampaigns` - Fetch Discord campaigns
- ✅ `onCalendlyWebhook` - Calendly webhook handler
- ✅ `claimsAdmin` - Admin claims management
- ✅ `syncCustomClaimsOnRoleChange` - Custom claims sync
- ✅ `syncCustomClaimsOnUserCreate` - Custom claims sync
- ✅ `syncAllCustomClaims` - Sync all custom claims
- ✅ `dailySyncGoogleSheets` - Daily Google Sheets sync
- ✅ `dailySyncUserProgressToSheet8AM` - Daily user progress sync (8 AM)
- ✅ `dailySyncUserProgressToSheet8PM` - Daily user progress sync (8 PM)
- ✅ `manualSyncUserProgressToSheet` - Manual user progress sync
- ✅ `dailyUsageReport` - Daily usage reporting
- ✅ `getCurrentUsage` - Get current usage statistics
- ✅ `trackUsage` - Track usage metrics
- ✅ `scheduledMonitoring` - Scheduled monitoring and alerting

**Deployment Command:**
```bash
cd infinitum-onboarding
firebase deploy --only functions
```

**Verification:**
- Check Firebase Console → Functions
- Verify all functions are deployed and active
- Check function logs for errors

---

### 2. Firestore Security Rules

**Required File:** `firestore.rules`

**Deployment Command:**
```bash
cd infinitum-onboarding
firebase deploy --only firestore:rules
```

**Verification:**
- Check Firebase Console → Firestore Database → Rules
- Verify rules are deployed
- Test rules in Rules Playground

---

### 3. Firestore Indexes

**Required File:** `firestore.indexes.json`

**Deployment Command:**
```bash
cd infinitum-onboarding
firebase deploy --only firestore:indexes
```

**Verification:**
- Check Firebase Console → Firestore Database → Indexes
- Verify all composite indexes are created
- Wait for indexes to finish building (can take time)

---

### 4. Firebase Realtime Database Rules

**Required File:** `database.rules.json`

**Deployment Command:**
```bash
cd infinitum-onboarding
firebase deploy --only database
```

**Verification:**
- Check Firebase Console → Realtime Database → Rules
- Verify rules are deployed

---

### 5. Firebase Storage Rules

**Required File:** `storage.rules`

**Deployment Command:**
```bash
cd infinitum-onboarding
firebase deploy --only storage
```

**Verification:**
- Check Firebase Console → Storage → Rules
- Verify rules are deployed

---

### 6. Firebase Hosting

**Required:** Web app deployment

**Deployment Command:**
```bash
cd infinitum-onboarding
firebase deploy --only hosting
```

**Verification:**
- Visit `https://infinitum-onboarding.web.app/`
- Verify site loads correctly
- Check all routes work (`/auth`, `/start`, etc.)

---

## Endpoint Verification

### Quick Test Script

Test all monitored endpoints:

```bash
# Health Check
curl https://us-central1-infinitum-onboarding.cloudfunctions.net/healthCheck

# OpenAPI Documentation
curl https://us-central1-infinitum-onboarding.cloudfunctions.net/openapi

# Main Page
curl -I https://infinitum-onboarding.web.app/

# Auth Page
curl -I https://infinitum-onboarding.web.app/auth

# Start Page
curl -I https://infinitum-onboarding.web.app/start
```

### Expected Responses

**Health Check:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-30T12:00:00.000Z",
  "version": "1.0.2",
  "environment": "production"
}
```

**OpenAPI:**
- Should return OpenAPI 3.0.3 JSON specification
- Status code: 200

**Web Pages:**
- Status code: 200
- Content-Type: text/html

---

## Environment Variables

Verify all required environment variables are set in Firebase Functions:

**Firebase Configuration:**
- `FIREBASE_PROJECT_ID`
- `FIREBASE_API_KEY`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID`
- `FIREBASE_MEASUREMENT_ID`

**Google Sheets:**
- `GOOGLE_SHEETS_DEPLOYMENT_URL`
- `GOOGLE_SHEETS_USER_PROGRESS_SYNC_URL`
- `GOOGLE_SHEET_ID`

**Discord:**
- `DISCORD_CLIENT_ID`
- `DISCORD_CLIENT_SECRET`
- `DISCORD_BOT_TOKEN`
- `DISCORD_GUILD_ID`
- `DISCORD_REDIRECT_URI`

**Calendly:**
- `CALENDLY_WEBHOOK_SECRET`
- `CALENDLY_API_TOKEN`

**Deployment:**
```bash
cd infinitum-onboarding
firebase functions:config:set \
  discord.client_id="YOUR_CLIENT_ID" \
  discord.client_secret="YOUR_CLIENT_SECRET"
# ... etc
firebase deploy --only functions
```

---

## Monitoring Integration

Once all deployments are complete, the down detector will automatically monitor:

1. ✅ Main Page - `https://infinitum-onboarding.web.app/`
2. ✅ Authentication - `https://infinitum-onboarding.web.app/auth`
3. ✅ Start Page - `https://infinitum-onboarding.web.app/start`
4. ✅ Health Check - `https://us-central1-infinitum-onboarding.cloudfunctions.net/healthCheck`
5. ✅ API Documentation - `https://us-central1-infinitum-onboarding.cloudfunctions.net/openapi`

---

## Troubleshooting

### Health Check Returns 404
- Verify `healthCheck` function is deployed
- Check function logs in Firebase Console
- Verify function name matches exactly

### Health Check Returns 500
- Check function logs for errors
- Verify environment variables are set
- Check Firestore connection

### Web Pages Return 404
- Verify hosting is deployed
- Check `firebase.json` hosting configuration
- Verify build output directory exists

### OpenAPI Returns 404
- Verify `openapi` function is deployed
- Check function logs
- Verify function is callable (not private)

---

## Deployment Checklist

- [ ] All Cloud Functions deployed
- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed
- [ ] Realtime Database rules deployed
- [ ] Storage rules deployed
- [ ] Hosting deployed
- [ ] Environment variables configured
- [ ] Health check endpoint working
- [ ] OpenAPI endpoint working
- [ ] Web pages accessible
- [ ] Down detector monitoring active

---

## Suggestions For Features and Additions Later:
// - Add automated deployment verification script
// - Create deployment health check dashboard
// - Add deployment rollback procedures
// - Implement deployment notifications
// - Create deployment testing suite
// - Add deployment version tracking
// - Implement deployment approval workflow
// - Add deployment audit logging

