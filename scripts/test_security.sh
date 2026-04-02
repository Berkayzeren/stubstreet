#!/bin/bash

# Bilet Sokağı - Güvenlik Test Script
# Bu script güvenlik özelliklerini test eder

API_URL="${API_URL:-http://localhost:5001/biletsokagi/us-central1/api}"
AUTH_TOKEN="${AUTH_TOKEN:-your-test-token}"

echo "🔒 Bilet Sokağı Güvenlik Testleri Başlıyor..."
echo "API URL: $API_URL"
echo ""

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test sonuçlarını kaydet
PASSED=0
FAILED=0

# Test fonksiyonu
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_code="$3"
    
    echo -n "Testing: $test_name... "
    
    response=$(eval "$command" 2>&1)
    actual_code=$(echo "$response" | grep -oE "HTTP/[0-9.]+ [0-9]+" | awk '{print $2}' | head -1)
    
    if [ "$actual_code" == "$expected_code" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $actual_code)"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC} (Expected: $expected_code, Got: $actual_code)"
        echo "Response: $response"
        ((FAILED++))
    fi
}

echo "=== 1. Rate Limiting Tests ==="

# Test 1: Normal request
run_test "Normal API request" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -H 'Authorization: Bearer $AUTH_TOKEN' $API_URL/health" \
    "200"

# Test 2: Rate limiting (rapid requests)
echo -e "\n${YELLOW}Sending 70 rapid requests to test rate limiting...${NC}"
for i in {1..70}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $AUTH_TOKEN" "$API_URL/health")
    if [ "$response" == "429" ]; then
        echo -e "${GREEN}✓ Rate limit triggered at request $i${NC}"
        ((PASSED++))
        break
    fi
    if [ $i -eq 70 ]; then
        echo -e "${RED}✗ Rate limit not triggered after 70 requests${NC}"
        ((FAILED++))
    fi
done

echo -e "\n=== 2. Bot Detection Tests ==="

# Test 3: Bot user-agent
run_test "Bot user-agent detection" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -H 'User-Agent: bot' $API_URL/health" \
    "403"

# Test 4: Crawler user-agent
run_test "Crawler user-agent detection" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -H 'User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1)' $API_URL/health" \
    "403"

# Test 5: curl user-agent
run_test "Curl user-agent detection" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -A 'curl/7.68.0' $API_URL/health" \
    "403"

echo -e "\n=== 3. Security Headers Tests ==="

# Test 6: Check security headers
echo -n "Checking security headers... "
headers=$(curl -s -I "$API_URL/health" 2>/dev/null)

check_header() {
    local header="$1"
    if echo "$headers" | grep -qi "$header"; then
        return 0
    else
        return 1
    fi
}

headers_ok=true
for header in "X-Content-Type-Options" "X-Frame-Options" "X-XSS-Protection" "Strict-Transport-Security"; do
    if ! check_header "$header"; then
        echo -e "\n${RED}✗ Missing header: $header${NC}"
        headers_ok=false
        ((FAILED++))
    fi
done

if [ "$headers_ok" = true ]; then
    echo -e "${GREEN}✓ All security headers present${NC}"
    ((PASSED++))
fi

echo -e "\n=== 4. Authentication Tests ==="

# Test 7: No auth token
run_test "Request without auth token" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -X POST $API_URL/v1/paytr/initialize" \
    "401"

# Test 8: Invalid auth token
run_test "Request with invalid auth token" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -H 'Authorization: Bearer invalid-token' -X POST $API_URL/v1/paytr/initialize" \
    "401"

echo -e "\n=== 5. CORS Tests ==="

# Test 9: CORS from allowed origin
run_test "CORS from allowed origin" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -H 'Origin: https://biletsokagi.com' -I $API_URL/health" \
    "200"

# Test 10: CORS from disallowed origin
run_test "CORS from disallowed origin" \
    "curl -s -w '\nHTTP/%{http_version} %{http_code}' -H 'Origin: https://evil.com' $API_URL/health 2>&1 | grep -q 'CORS' && echo '403' || echo '200'" \
    "403"

echo -e "\n=== Test Summary ==="
echo -e "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All security tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Some tests failed. Please review security configuration.${NC}"
    exit 1
fi
