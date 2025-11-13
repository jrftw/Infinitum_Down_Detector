# Filename: deploy.ps1
# Purpose: PowerShell deployment script for Firebase services
# Author: Kevin Doyle Jr. / Infinitum Imagery LLC
# Last Modified: 2025-01-30
# Dependencies: Flutter, Firebase CLI
# Platform Compatibility: Windows PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firebase Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterCheck = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Flutter found" -ForegroundColor Green
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI installation..." -ForegroundColor Yellow
$firebaseCheck = firebase --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Firebase CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install with: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Firebase CLI found" -ForegroundColor Green
Write-Host ""

# Check if user is logged in to Firebase
Write-Host "Checking Firebase login status..." -ForegroundColor Yellow
$firebaseUser = firebase login:list 2>&1
if ($LASTEXITCODE -ne 0 -or $firebaseUser -match "No authorized accounts") {
    Write-Host "WARNING: Not logged in to Firebase" -ForegroundColor Yellow
    Write-Host "Running: firebase login" -ForegroundColor Yellow
    firebase login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Firebase login failed" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ Firebase login verified" -ForegroundColor Green
Write-Host ""

# Build Flutter web app
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1: Building Flutter Web App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
flutter build web
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Flutter web app built successfully" -ForegroundColor Green
Write-Host ""

# Deploy Firestore rules
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: Deploying Firestore Rules" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
firebase deploy --only firestore:rules
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Firestore rules deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Firestore rules deployed successfully" -ForegroundColor Green
Write-Host ""

# Deploy Firebase Functions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3: Deploying Firebase Functions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
firebase deploy --only functions
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Functions deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Firebase Functions deployed successfully" -ForegroundColor Green
Write-Host ""

# Deploy Firebase Hosting
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 4: Deploying Firebase Hosting" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Hosting deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Firebase Hosting deployed successfully" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Verify Firestore rules in Firebase Console" -ForegroundColor White
Write-Host "2. Check Functions in Firebase Console" -ForegroundColor White
Write-Host "3. Verify Cloud Scheduler job for scheduledHealthCheck" -ForegroundColor White
Write-Host "4. Visit your hosted app URL" -ForegroundColor White
Write-Host "5. Monitor function logs: firebase functions:log" -ForegroundColor White
Write-Host ""

