# Bolt21 Security Testing Checklist
**Purpose:** Runbook for pre-release and ongoing security verification
**Last Updated:** 2025-12-31

---

## PRE-RELEASE CHECKLIST

Use this checklist before every release to production.

### 1. Memory Safety

- [ ] **Mnemonic Wiping Test**
  ```bash
  # On rooted/jailbroken test device:
  1. Create new wallet
  2. Force crash app (adb shell kill -9 <pid>)
  3. Dump memory: adb shell cat /proc/<pid>/mem > mem.dump
  4. Search: strings mem.dump | grep -E '\b([a-z]+\s+){11}[a-z]+\b'
  5. PASS: No 12-word phrases found
  ```

- [ ] **SecureString Disposal**
  - Run unit tests: `flutter test test/utils/secure_string_test.dart`
  - Verify triple-overwrite pattern in logs (debug mode)

- [ ] **No Hardcoded Secrets**
  ```bash
  # Search codebase
  grep -rE "(api_key|secret|password|mnemonic)\s*[:=]\s*['\"][^'\"]+['\"]" lib/
  # Expected: No matches (except test files)
  ```

### 2. Network Security

- [ ] **Certificate Pinning Active**
  ```bash
  # With mitmproxy running:
  mitmproxy -p 8080 --mode regular
  # Configure device proxy
  # Attempt app operations
  # PASS: All connections fail (pinning blocks proxy)
  ```

- [ ] **HTTPS Enforcement**
  - [ ] Community Node rejects http:// URLs
  - [ ] LND connection requires https:// or tor://
  - [ ] No cleartext traffic in network_security_config.xml

- [ ] **SSRF Protection**
  - Test blocked URLs:
    - [ ] `https://localhost/test` → Rejected
    - [ ] `https://192.168.1.1/admin` → Rejected
    - [ ] `https://10.0.0.1/api` → Rejected
    - [ ] `https://169.254.169.254/metadata` → Rejected

### 3. Input Validation

- [ ] **Unicode Attack Prevention**
  - Run unit tests: `flutter test test/utils/address_validator_test.dart`
  - Test manually:
    - [ ] Cyrillic lookalikes rejected
    - [ ] RTL override characters rejected
    - [ ] Zero-width spaces rejected
    - [ ] Only ASCII allowed in addresses

- [ ] **Payment Amount Validation**
  - [ ] Negative amounts rejected
  - [ ] Amounts > 21M BTC rejected
  - [ ] Overflow values clamped

- [ ] **QR Code Fuzzing**
  - Scan malformed QR codes:
    - [ ] `javascript:alert(1)` → Rejected
    - [ ] `<script>test</script>` → Rejected
    - [ ] 10,000 character payload → Truncated/Rejected
    - [ ] Null bytes → Rejected

### 4. Payment Security

- [ ] **Rate Limiting Active**
  - Attempt 6 payments in 60 seconds
  - PASS: 6th payment blocked with rate limit message

- [ ] **Biometric Triggers**
  - [ ] Single payment >= 100k sats → Biometric required
  - [ ] Cumulative 5-min >= 100k sats → Biometric required
  - [ ] Cumulative 24-hour >= 500k sats → Biometric required

- [ ] **Operation State Tracking**
  - [ ] Kill app during payment
  - [ ] Reopen app
  - [ ] Verify operation marked as "unknown" for recovery

### 5. Secure Storage

- [ ] **iOS Keychain**
  - [ ] `synchronizable: false` in code
  - [ ] `unlocked_this_device` accessibility
  - [ ] Mnemonic NOT in iCloud backup (verify with iMazing)

- [ ] **Android KeyStore**
  - [ ] Hardware-backed encryption on supported devices
  - [ ] Encrypted SharedPreferences used
  - [ ] No sensitive data in regular SharedPreferences

### 6. Platform Security

- [ ] **Screenshot Protection**
  - [ ] Android: FLAG_SECURE blocks screenshots on sensitive screens
  - [ ] iOS: White overlay on app switcher for sensitive screens
  - [ ] Explicitly allowed only on receive QR screen

- [ ] **Clipboard Security**
  - [ ] Mnemonic auto-clears after 30 seconds
  - [ ] Security warning shown when copying
  - [ ] Manual clear button works

### 7. Supply Chain

- [ ] **Dependency Audit**
  ```bash
  flutter pub outdated
  # Review any security-related updates
  ```

- [ ] **Breez SDK Pin**
  - Verify pinned to specific commit in pubspec.yaml
  - Review changelog for security fixes since last update

- [ ] **No New Dependencies**
  - Review any newly added packages
  - Verify publisher reputation on pub.dev

### 8. Build Security

- [ ] **No Debug Flags**
  ```bash
  # APK analysis
  unzip -p bolt21.apk classes.dex | strings | grep -i debug
  # Expected: No debug indicators
  ```

- [ ] **Release Signing**
  ```bash
  apksigner verify --print-certs bolt21.apk
  # Verify matches production signing key
  ```

- [ ] **No Sensitive Defines**
  - BREEZ_API_KEY passed via --dart-define (not in code)
  - No .env files included in build

---

## REGRESSION TEST SUITE

Run full security test suite:

```bash
flutter test test/security/
flutter test test/utils/secure_string_test.dart
flutter test test/utils/address_validator_test.dart
flutter test test/services/community_node_service_test.dart
flutter test test/services/lnd_service_test.dart
flutter test test/services/operation_state_service_test.dart
```

**Expected:** All tests pass

---

## QUICK SMOKE TEST (5 minutes)

For hotfixes when full checklist isn't feasible:

- [ ] Create wallet, verify mnemonic not in logs
- [ ] Send small payment, verify biometric not bypassed
- [ ] Check certificate pinning still blocks proxy
- [ ] Verify screenshot protection on lock screen
- [ ] Run: `flutter test test/security/`

---

## POST-RELEASE MONITORING

### Week 1 After Release

- [ ] Monitor crash reports for security-related patterns
- [ ] Check app store reviews for security complaints
- [ ] Review any Breez SDK security advisories
- [ ] Check for new CVEs in dependencies

### Ongoing

- [ ] Weekly CVE review (see playbook)
- [ ] Monthly MobSF scan
- [ ] Quarterly red team engagement

---

## SIGN-OFF

| Release | Tester | Date | All Checks Pass |
|---------|--------|------|-----------------|
| v1.0.0 | @black-team | 2025-12-31 | YES |
| | | | |
| | | | |

---

**Note:** Failed checks are RELEASE BLOCKERS unless explicitly documented and accepted as known risk.
