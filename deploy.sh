#!/bin/bash
# Filename: deploy.sh
# Purpose: Bash deployment script for Firebase services
# Author: Kevin Doyle Jr. / Infinitum Imagery LLC
# Last Modified: 2025-01-30
# Dependencies: Flutter, Firebase CLI
# Platform Compatibility: Linux, macOS

echo "========================================"
echo "Firebase Deployment Script"
echo "========================================"
echo ""

# Check if Flutter is installed
echo "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    exit 1
fi
echo "✓ Flutter found"
echo ""

# Check if Firebase CLI is installed
echo "Checking Firebase CLI installation..."
if ! command -v firebase &> /dev/null; then
    echo "ERROR: Firebase CLI is not installed or not in PATH"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi
echo "✓ Firebase CLI found"
echo ""

# Check if user is logged in to Firebase
echo "Checking Firebase login status..."
if ! firebase login:list &> /dev/null || firebase login:list | grep -q "No authorized accounts"; then
    echo "WARNING: Not logged in to Firebase"
    echo "Running: firebase login"
    firebase login
    if [ $? -ne 0 ]; then
        echo "ERROR: Firebase login failed"
        exit 1
    fi
fi
echo "✓ Firebase login verified"
echo ""

# Build Flutter web app
echo "========================================"
echo "Step 1: Building Flutter Web App"
echo "========================================"
echo ""
flutter build web
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter build failed"
    exit 1
fi
echo "✓ Flutter web app built successfully"
echo ""

# Deploy Firestore rules
echo "========================================"
echo "Step 2: Deploying Firestore Rules"
echo "========================================"
echo ""
firebase deploy --only firestore:rules
if [ $? -ne 0 ]; then
    echo "ERROR: Firestore rules deployment failed"
    exit 1
fi
echo "✓ Firestore rules deployed successfully"
echo ""

# Deploy Firebase Functions
echo "========================================"
echo "Step 3: Deploying Firebase Functions"
echo "========================================"
echo ""
firebase deploy --only functions
if [ $? -ne 0 ]; then
    echo "ERROR: Functions deployment failed"
    exit 1
fi
echo "✓ Firebase Functions deployed successfully"
echo ""

# Deploy Firebase Hosting
echo "========================================"
echo "Step 4: Deploying Firebase Hosting"
echo "========================================"
echo ""
firebase deploy --only hosting
if [ $? -ne 0 ]; then
    echo "ERROR: Hosting deployment failed"
    exit 1
fi
echo "✓ Firebase Hosting deployed successfully"
echo ""

# Summary
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Next Steps:"
echo "1. Verify Firestore rules in Firebase Console"
echo "2. Check Functions in Firebase Console"
echo "3. Verify Cloud Scheduler job for scheduledHealthCheck"
echo "4. Visit your hosted app URL"
echo "5. Monitor function logs: firebase functions:log"
echo ""

