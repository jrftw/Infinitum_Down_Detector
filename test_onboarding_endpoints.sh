#!/bin/bash
# Filename: test_onboarding_endpoints.sh
# Purpose: Quick verification script to test onboarding service endpoints
# Author: Kevin Doyle Jr. / Infinitum Imagery LLC
# Last Modified: 2025-01-30
# Dependencies: curl
# Platform Compatibility: Linux, macOS, Git Bash (Windows)

echo "=========================================="
echo "Onboarding Service Endpoint Verification"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to test endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    echo -n "Testing $name... "
    
    if [ -z "$expected_status" ]; then
        expected_status=200
    fi
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
    
    if [ "$response" == "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (Status: $response)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Status: $response, Expected: $expected_status)"
        ((FAILED++))
        return 1
    fi
}

# Test Health Check endpoint
echo "1. Testing Health Check API..."
test_endpoint "Health Check" "https://us-central1-infinitum-onboarding.cloudfunctions.net/healthCheck"
health_response=$(curl -s --max-time 10 "https://us-central1-infinitum-onboarding.cloudfunctions.net/healthCheck" 2>/dev/null)
if echo "$health_response" | grep -q "healthy"; then
    echo "   Response: $health_response"
else
    echo -e "   ${YELLOW}Warning: Health check response may not contain 'healthy' status${NC}"
fi
echo ""

# Test OpenAPI endpoint
echo "2. Testing OpenAPI Documentation..."
test_endpoint "OpenAPI" "https://us-central1-infinitum-onboarding.cloudfunctions.net/openapi"
echo ""

# Test Main Page
echo "3. Testing Web Pages..."
test_endpoint "Main Page" "https://infinitum-onboarding.web.app/"
test_endpoint "Auth Page" "https://infinitum-onboarding.web.app/auth"
test_endpoint "Start Page" "https://infinitum-onboarding.web.app/start"
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    echo "If endpoints are failing:"
    echo "1. Verify functions are deployed: firebase deploy --only functions"
    echo "2. Check Firebase Console for function status"
    echo "3. Review function logs for errors"
    echo "4. Verify environment variables are set"
    exit 1
else
    echo -e "${GREEN}Failed: $FAILED${NC}"
    echo ""
    echo "All endpoints are working correctly! ✓"
    exit 0
fi




