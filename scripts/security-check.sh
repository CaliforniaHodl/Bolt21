#!/bin/bash
# Bolt21 Security Check Script
# Run: ./scripts/security-check.sh [weekly|monthly|quarterly]
#
# Weekly: CVE check, dependency audit, quick tests
# Monthly: Full static analysis, cert verification
# Quarterly: All checks + generate report

set +e  # Don't exit on errors - we handle them ourselves

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/docs/security/reports"
DATE=$(date +%Y-%m-%d)
MODE="${1:-weekly}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Bolt21 Security Check - $MODE${NC}"
echo -e "${BLUE}  Date: $DATE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create reports directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Track issues found
ISSUES_FOUND=0
WARNINGS_FOUND=0

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((ISSUES_FOUND++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS_FOUND++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# ============================================
# WEEKLY CHECKS
# ============================================

run_weekly_checks() {
    echo -e "\n${BLUE}--- Weekly Security Checks ---${NC}\n"

    # 1. Dependency Vulnerability Check
    log_info "Checking for outdated dependencies..."
    cd "$PROJECT_DIR"

    OUTDATED_OUTPUT=$(flutter pub outdated 2>&1)
    # Check if there are upgradable dependencies (look for asterisks indicating outdated)
    OUTDATED_COUNT=$(echo "$OUTDATED_OUTPUT" | grep -c "^\*" || echo "0")
    if echo "$OUTDATED_OUTPUT" | grep -q "upgradable"; then
        log_warn "Some dependencies can be upgraded. Run 'flutter pub outdated' for details."
        echo "$OUTDATED_OUTPUT" | grep -E "(Package|direct|dev_dep|transitive|\*)" | head -15
    else
        log_pass "All dependencies up to date"
    fi

    # 2. Security Tests
    log_info "Running security test suite..."
    if flutter test test/unit/security_validation_test.dart test/unit/security_regression_test.dart test/unit/multi_wallet_security_test.dart 2>&1 | tee /tmp/security-test-output.txt | tail -5; then
        if grep -q "All tests passed" /tmp/security-test-output.txt; then
            log_pass "Security tests passed"
        else
            log_fail "Security tests failed"
        fi
    else
        log_fail "Security tests failed"
    fi

    # 3. Check for hardcoded secrets
    log_info "Scanning for hardcoded secrets..."
    SECRETS_FOUND=$(grep -rE "(api_key|secret|password|mnemonic)\s*[:=]\s*['\"][^'\"]{8,}['\"]" "$PROJECT_DIR/lib/" 2>/dev/null | grep -v "test" | wc -l | tr -d ' ')
    if [ "$SECRETS_FOUND" -gt 0 ]; then
        log_fail "Potential hardcoded secrets found in lib/"
        grep -rE "(api_key|secret|password|mnemonic)\s*[:=]\s*['\"][^'\"]{8,}['\"]" "$PROJECT_DIR/lib/" 2>/dev/null | head -5
    else
        log_pass "No hardcoded secrets found"
    fi

    # 4. Check Breez SDK pinning
    log_info "Verifying Breez SDK is pinned..."
    if grep -q "ref:" "$PROJECT_DIR/pubspec.yaml"; then
        log_pass "Breez SDK pinned to specific commit"
    else
        log_fail "Breez SDK not pinned - supply chain risk"
    fi

    # 5. Check for debug flags in code
    log_info "Checking for debug flags..."
    DEBUG_FLAGS=$(grep -rE "kDebugMode|debugPrint|print\(" "$PROJECT_DIR/lib/" 2>/dev/null | grep -v "SecureLogger" | grep -v "test" | wc -l | tr -d ' ')
    if [ "$DEBUG_FLAGS" -gt 5 ]; then
        log_warn "$DEBUG_FLAGS potential debug statements found"
    else
        log_pass "Debug flags within acceptable limits"
    fi

    # 6. Validate address_validator tests exist
    log_info "Checking address validation coverage..."
    if flutter test test/unit/utils/address_validator_test.dart 2>&1 | tail -3; then
        log_pass "Address validator tests passed"
    else
        log_fail "Address validator tests failed"
    fi

    # 7. Check secure storage configuration
    log_info "Verifying secure storage config..."
    if grep -q "synchronizable: false" "$PROJECT_DIR/lib/services/secure_storage_service.dart" 2>/dev/null; then
        log_pass "iCloud sync disabled"
    else
        log_warn "Could not verify iCloud sync is disabled"
    fi
}

# ============================================
# MONTHLY CHECKS
# ============================================

run_monthly_checks() {
    echo -e "\n${BLUE}--- Monthly Security Checks ---${NC}\n"

    # Run weekly first
    run_weekly_checks

    # 1. Full test suite
    log_info "Running full test suite..."
    if flutter test 2>/dev/null; then
        log_pass "All tests passed"
    else
        log_fail "Some tests failed"
    fi

    # 2. Static analysis
    log_info "Running static analysis..."
    if flutter analyze --no-fatal-infos 2>/dev/null; then
        log_pass "Static analysis passed"
    else
        log_warn "Static analysis has warnings"
    fi

    # 3. Certificate pinning verification
    log_info "Verifying certificate pins..."
    if [ -f "$PROJECT_DIR/android/app/src/main/res/xml/network_security_config.xml" ]; then
        PIN_COUNT=$(grep -c "pin-set" "$PROJECT_DIR/android/app/src/main/res/xml/network_security_config.xml" 2>/dev/null || echo "0")
        if [ "$PIN_COUNT" -gt 0 ]; then
            log_pass "Certificate pinning configured ($PIN_COUNT domains)"

            # Check pin expiration
            EXPIRY=$(grep -o 'expiration="[^"]*"' "$PROJECT_DIR/android/app/src/main/res/xml/network_security_config.xml" 2>/dev/null | head -1 | cut -d'"' -f2)
            if [ -n "$EXPIRY" ]; then
                EXPIRY_EPOCH=$(date -j -f "%Y-%m-%d" "$EXPIRY" "+%s" 2>/dev/null || date -d "$EXPIRY" "+%s" 2>/dev/null || echo "0")
                NOW_EPOCH=$(date "+%s")
                DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
                if [ "$DAYS_LEFT" -lt 90 ]; then
                    log_warn "Certificate pins expire in $DAYS_LEFT days"
                else
                    log_pass "Certificate pins valid for $DAYS_LEFT days"
                fi
            fi
        else
            log_fail "No certificate pins found"
        fi
    else
        log_fail "network_security_config.xml not found"
    fi

    # 4. Check HTTPS enforcement
    log_info "Verifying HTTPS enforcement..."
    HTTP_USAGE=$(grep -rE "http://" "$PROJECT_DIR/lib/" 2>/dev/null | grep -v "https://" | grep -v "localhost" | wc -l | tr -d ' ')
    if [ "$HTTP_USAGE" -gt 0 ]; then
        log_warn "Found $HTTP_USAGE potential HTTP (non-HTTPS) references"
    else
        log_pass "No insecure HTTP usage found"
    fi

    # 5. Screenshot protection check
    log_info "Verifying screenshot protection..."
    if grep -q "FLAG_SECURE" "$PROJECT_DIR/android/app/src/main/kotlin/"*/*.kt 2>/dev/null; then
        log_pass "Android screenshot protection enabled"
    else
        log_warn "Android screenshot protection not found"
    fi

    # 6. Rate limiting check
    log_info "Checking rate limiting implementation..."
    if grep -q "maxPaymentsPerMinute" "$PROJECT_DIR/lib/" -r 2>/dev/null; then
        log_pass "Rate limiting implemented"
    else
        log_warn "Rate limiting configuration not found"
    fi
}

# ============================================
# QUARTERLY CHECKS
# ============================================

run_quarterly_checks() {
    echo -e "\n${BLUE}--- Quarterly Security Checks ---${NC}\n"

    # Run monthly first (which includes weekly)
    run_monthly_checks

    # 1. Generate comprehensive report
    log_info "Generating quarterly security report..."

    REPORT_FILE="$REPORT_DIR/security-report-$DATE.md"

    cat > "$REPORT_FILE" << EOF
# Bolt21 Quarterly Security Report
**Date:** $DATE
**Generated by:** security-check.sh

## Summary
- Issues Found: $ISSUES_FOUND
- Warnings: $WARNINGS_FOUND

## Dependency Status
\`\`\`
$(flutter pub outdated 2>/dev/null | head -30)
\`\`\`

## Test Results
\`\`\`
$(flutter test 2>&1 | tail -20)
\`\`\`

## Static Analysis
\`\`\`
$(flutter analyze 2>&1 | tail -20)
\`\`\`

## Certificate Pin Status
$(grep -A5 "pin-set" "$PROJECT_DIR/android/app/src/main/res/xml/network_security_config.xml" 2>/dev/null | head -20)

## Recommendations
- Review any warnings above
- Update threat model if new attack vectors identified
- Schedule red team engagement if not done this quarter

## Next Review
$(date -v+3m +%Y-%m-%d 2>/dev/null || date -d "+3 months" +%Y-%m-%d 2>/dev/null || echo "3 months from now")
EOF

    log_pass "Report saved to $REPORT_FILE"

    # 2. Check threat model freshness
    log_info "Checking threat model freshness..."
    if [ -f "$PROJECT_DIR/docs/security/threat-model-v1.md" ]; then
        THREAT_MODEL_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$PROJECT_DIR/docs/security/threat-model-v1.md" 2>/dev/null || stat -c "%y" "$PROJECT_DIR/docs/security/threat-model-v1.md" 2>/dev/null | cut -d' ' -f1)
        log_info "Threat model last updated: $THREAT_MODEL_DATE"
    else
        log_warn "Threat model not found"
    fi

    # 3. Reminder for external audit
    log_info "External audit reminder: Consider scheduling if not done in past 12 months"
}

# ============================================
# MAIN
# ============================================

case "$MODE" in
    weekly)
        run_weekly_checks
        ;;
    monthly)
        run_monthly_checks
        ;;
    quarterly)
        run_quarterly_checks
        ;;
    *)
        echo "Usage: $0 [weekly|monthly|quarterly]"
        exit 1
        ;;
esac

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Security Check Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$ISSUES_FOUND" -gt 0 ]; then
    echo -e "${RED}Issues found: $ISSUES_FOUND${NC}"
fi

if [ "$WARNINGS_FOUND" -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS_FOUND${NC}"
fi

if [ "$ISSUES_FOUND" -eq 0 ] && [ "$WARNINGS_FOUND" -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
fi

echo ""

# Exit with error if issues found
if [ "$ISSUES_FOUND" -gt 0 ]; then
    exit 1
fi

exit 0
