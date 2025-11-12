# Filename: test_onboarding_endpoints.ps1
# Purpose: Quick verification script to test onboarding service endpoints (PowerShell)
# Author: Kevin Doyle Jr. / Infinitum Imagery LLC
# Last Modified: 2025-01-30
# Dependencies: PowerShell 5.1+ (Invoke-WebRequest)
# Platform Compatibility: Windows PowerShell, PowerShell Core

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Onboarding Service Endpoint Verification" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$script:Passed = 0
$script:Failed = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [int]$ExpectedStatus = 200
    )
    
    Write-Host "Testing $Name... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "✓ PASS" -ForegroundColor Green -NoNewline
            Write-Host " (Status: $statusCode)"
            $script:Passed++
            return $true
        } else {
            Write-Host "✗ FAIL" -ForegroundColor Red -NoNewline
            Write-Host " (Status: $statusCode, Expected: $ExpectedStatus)"
            $script:Failed++
            return $false
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "✓ PASS" -ForegroundColor Green -NoNewline
            Write-Host " (Status: $statusCode)"
            $script:Passed++
            return $true
        } else {
            Write-Host "✗ FAIL" -ForegroundColor Red -NoNewline
            Write-Host " (Status: $statusCode, Expected: $ExpectedStatus)"
            $script:Failed++
            return $false
        }
    }
}

# Test Health Check endpoint
Write-Host "1. Testing Health Check API..." -ForegroundColor Yellow
Test-Endpoint -Name "Health Check" -Url "https://us-central1-infinitum-onboarding.cloudfunctions.net/healthCheck"
try {
    $healthResponse = Invoke-WebRequest -Uri "https://us-central1-infinitum-onboarding.cloudfunctions.net/healthCheck" -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    $healthContent = $healthResponse.Content
    if ($healthContent -match "healthy") {
        Write-Host "   Response: $healthContent" -ForegroundColor Gray
    } else {
        Write-Host "   Warning: Health check response may not contain 'healthy' status" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Could not retrieve health check response details" -ForegroundColor Yellow
}
Write-Host ""

# Test OpenAPI endpoint
Write-Host "2. Testing OpenAPI Documentation..." -ForegroundColor Yellow
Test-Endpoint -Name "OpenAPI" -Url "https://us-central1-infinitum-onboarding.cloudfunctions.net/openapi"
Write-Host ""

# Test Web Pages
Write-Host "3. Testing Web Pages..." -ForegroundColor Yellow
Test-Endpoint -Name "Main Page" -Url "https://infinitum-onboarding.web.app/"
Test-Endpoint -Name "Auth Page" -Url "https://infinitum-onboarding.web.app/auth"
Test-Endpoint -Name "Start Page" -Url "https://infinitum-onboarding.web.app/start"
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:Passed" -ForegroundColor Green
if ($script:Failed -gt 0) {
    Write-Host "Failed: $script:Failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "If endpoints are failing:" -ForegroundColor Yellow
    Write-Host "1. Verify functions are deployed: firebase deploy --only functions"
    Write-Host "2. Check Firebase Console for function status"
    Write-Host "3. Review function logs for errors"
    Write-Host "4. Verify environment variables are set"
    exit 1
} else {
    Write-Host "Failed: $script:Failed" -ForegroundColor Green
    Write-Host ""
    Write-Host "All endpoints are working correctly! ✓" -ForegroundColor Green
    exit 0
}

