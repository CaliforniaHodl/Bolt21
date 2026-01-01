# Bolt21 Red Team Ongoing Security Playbook
**Version:** 1.0
**Maintainers:** @mr-blackkeys, @black-team
**Last Updated:** 2025-12-31
**Purpose:** Keep the security team current on attack vectors and testing methodologies

---

## TEAM STRUCTURE

| Role | Focus Area | Owner |
|------|------------|-------|
| Crypto Lead | Mnemonic, keys, ZK, encryption | @mr-blackkeys |
| Network Lead | MITM, TLS, API, protocol attacks | @black-team |
| Mobile Lead | iOS/Android reversing, biometric bypass | @black-team |
| Payment Lead | Lightning/Bitcoin attack vectors | @black-team |

---

## QUICK START: RUNNING SECURITY CHECKS

### Automated (GitHub Actions)

Security checks run automatically:
- **Weekly:** Every Monday 9am UTC (CVE check, dependency audit, quick tests)
- **Monthly:** First Monday of each month (full analysis)
- **On Failure:** GitHub Issue created automatically

**Manual Trigger:**
1. Go to Actions → "Security Check"
2. Click "Run workflow"
3. Select mode: `weekly`, `monthly`, or `quarterly`

### Local Development

```bash
# Weekly check (quick, ~2 min)
./scripts/security-check.sh weekly

# Monthly check (full tests, ~5 min)
./scripts/security-check.sh monthly

# Quarterly check (generates report, ~10 min)
./scripts/security-check.sh quarterly
```

### Set Up Local Cron (Optional)

```bash
# Edit crontab
crontab -e

# Add weekly check (Monday 9am local)
0 9 * * 1 cd /path/to/bolt21 && ./scripts/security-check.sh weekly >> /tmp/bolt21-security.log 2>&1

# Add monthly check (1st of month, 10am)
0 10 1 * * cd /path/to/bolt21 && ./scripts/security-check.sh monthly >> /tmp/bolt21-security.log 2>&1
```

### Slack/Discord Notifications (Optional)

Add webhook to `.github/workflows/security-check.yml`:
```yaml
- name: Notify Slack
  if: failure()
  run: |
    curl -X POST -H 'Content-type: application/json' \
      --data '{"text":"Security check failed! Check GitHub Actions."}' \
      ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## PART 1: THREAT INTELLIGENCE SOURCES

### A. Academic & Conference Sources

**Priority 1 - Must Follow:**
| Source | Focus | Check Frequency |
|--------|-------|-----------------|
| [Financial Cryptography (FC)](https://fc25.ifca.ai/) | Wallet attacks, key extraction | Annually (Feb) |
| [IEEE S&P](https://sp2025.ieee-security.org/) | All security, crypto | Annually (May) |
| [USENIX Security](https://www.usenix.org/conferences) | Systems security | Annually (Aug) |
| [CCS (ACM)](https://www.sigsac.org/ccs.html) | Crypto, network attacks | Annually (Nov) |
| [Real World Crypto](https://rwc.iacr.org/) | Applied cryptography | Annually (Mar) |

**Priority 2 - Quarterly Review:**
| Source | Focus |
|--------|-------|
| [ePrint Cryptology](https://eprint.iacr.org/) | Pre-print crypto papers |
| [NDSS Symposium](https://www.ndss-symposium.org/) | Network/distributed security |
| [WOOT Workshop](https://www.usenix.org/conferences) | Offensive technologies |

**Search Terms for Papers:**
```
"Bitcoin wallet" attack
"Lightning Network" vulnerability
"BIP39" entropy weakness
"mobile wallet" key extraction
"mnemonic" memory forensics
"zero-knowledge" wallet
"BOLT11" "BOLT12" security
"Breez SDK" OR "Lightning SDK"
```

### B. Bug Bounty Intelligence

**Disclosed Reports to Study:**
| Platform | Search Strategy |
|----------|-----------------|
| [HackerOne Disclosed](https://hackerone.com/hacktivity) | Filter: cryptocurrency, wallet, bitcoin |
| [Immunefi](https://immunefi.com/) | Study past wallet bounties |
| [Bugcrowd](https://bugcrowd.com/crowdstream) | Filter: fintech, crypto |

**Key Programs to Monitor:**
- Breez (your SDK provider)
- Strike, Cash App, Muun (similar apps)
- Bitcoin Core, LND, c-lightning (infrastructure)

### C. Vulnerability Databases

**Daily/Weekly Monitoring:**
| Source | Relevance |
|--------|-----------|
| [NVD (NIST)](https://nvd.nist.gov/) | CVEs for dependencies |
| [GitHub Security Advisories](https://github.com/advisories) | Dart/Flutter/SDK vulns |
| [Snyk Vulnerability DB](https://security.snyk.io/) | Package vulnerabilities |
| [OSV (Open Source Vulns)](https://osv.dev/) | Dart ecosystem |

**Automated Alerts Setup:**
```bash
# GitHub: Watch these repos for security advisories
- breez/breez-sdk-liquid-flutter
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- flutter/flutter
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- mogol/flutter_secure_storage
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- nicklockwood/SwiftFormat (iOS deps)
- bitcoin-dev-project/bip39
```

### D. Community Intelligence

**Forums & Discussion:**
| Source | What to Monitor |
|--------|-----------------|
| [Bitcoin Dev Mailing List](https://lists.linuxfoundation.org/pipermail/bitcoin-dev/) | Protocol-level vulns |
| [Lightning-dev Mailing List](https://lists.linuxfoundation.org/pipermail/lightning-dev/) | LN-specific issues |
| [r/netsec](https://reddit.com/r/netsec) | General security news |
| [r/Bitcoin](https://reddit.com/r/Bitcoin) | Wallet incidents |
| [Bitcoin StackExchange](https://bitcoin.stackexchange.com/) | Technical discussions |

**Twitter/X Accounts to Follow:**
```
@staborosch (wallet security researcher)
@AriJuels (crypto/security academic)
@matthew_d_green (crypto professor)
@bcaborosch (Bitcoin security)
@LightningK0ala (LN security)
@roasbeef (LND maintainer)
@rusty_twit (c-lightning maintainer)
@Snyke (dependency security)
```

---

## PART 2: ATTACK CATEGORIES TO TRACK

### Category 1: Key/Seed Attacks (Priority: CRITICAL)

**Current Bolt21 Defenses:**
- SecureString triple-overwrite
- AES-256-GCM encryption
- Hardware-backed keystore

**Emerging Threats to Monitor:**

| Attack Vector | Research Area | Current Status |
|---------------|---------------|----------------|
| **Speculative Execution** | Spectre/Meltdown variants on mobile | Monitor ARM announcements |
| **Side-Channel on TEE** | TrustZone extraction | Academic papers (FC, CCS) |
| **Memory-Safe Language Bypass** | Dart VM memory leaks | Flutter security advisories |
| **Cold Boot on Mobile** | RAM persistence post-lock | Hardware vendor announcements |
| **Clipboard Chain Attacks** | Cross-app clipboard access | iOS/Android security bulletins |

**Testing Cadence:** Quarterly memory forensics scan

### Category 2: ZK/Cryptographic Attacks (Priority: HIGH)

**Current Bolt21 Use:**
- No native ZK implementation (delegated to Breez SDK)
- Potential future feature (roadmap)

**Threats to Monitor:**

| Attack | Relevance | Sources |
|--------|-----------|---------|
| **ZK Proof Forgery** | If ZK invoices added | ePrint, Real World Crypto |
| **Pedersen Commitment Attacks** | Liquid/Confidential Transactions | Blockstream research |
| **ECDSA Nonce Reuse** | Signing vulnerabilities | Bitcoin mailing list |
| **Lattice Attacks (Post-Quantum)** | Future key derivation | NIST PQC competition |

**Action:** If adding ZK features, engage specialized auditor

### Category 3: Lightning Protocol Attacks (Priority: HIGH)

**Current Bolt21 Exposure:**
- BOLT11/BOLT12 invoice parsing
- Breez SDK payment routing
- Community Node routing

**Active Threats:**

| Attack | Description | Defense Status |
|--------|-------------|----------------|
| **Channel Jamming** | DoS via HTLC exhaustion | SDK-level (Breez) |
| **Replacement Cycling** | Pinning/replacement attacks | SDK-level (Breez) |
| **Invoice Amount Griefing** | Overpayment via malformed invoice | Validated locally |
| **Route Hijacking** | Malicious routing via fake nodes | SDK-level (Breez) |
| **Timelock Manipulation** | Forcing bad timelocks | SDK-level |

**Testing:** Review Breez SDK updates for new mitigations

### Category 4: Mobile Platform Attacks (Priority: HIGH)

**iOS-Specific:**

| Attack | Description | Bolt21 Defense |
|--------|-------------|----------------|
| **Keychain Extraction** | Jailbreak + keychain dump | `unlocked_this_device` accessibility |
| **Screenshot Capture** | Accessibility API abuse | Screenshot protection enabled |
| **Pasteboard Sniffing** | Universal clipboard | 30-second auto-clear |
| **TestFlight Sideload** | Fake app distribution | Signed with production cert |

**Android-Specific:**

| Attack | Description | Bolt21 Defense |
|--------|-------------|----------------|
| **Overlay Attack** | Fake UI over real app | FLAG_SECURE blocks |
| **Accessibility Abuse** | Screen reader key theft | Secure input fields |
| **APK Tampering** | Modified app distribution | Play Store signing |
| **Root Detection Bypass** | Frida/Magisk hiding | Consider adding root detection |

**Recommendation:** Add root/jailbreak detection in v1.2

### Category 5: Supply Chain Attacks (Priority: MEDIUM)

**Current Defenses:**
- Breez SDK pinned to specific commit
- Certificate pinning for updates

**Threats to Monitor:**

| Attack | Example | Mitigation |
|--------|---------|------------|
| **Dependency Confusion** | Malicious pub.dev package | Pin critical deps to git |
| **Typosquatting** | `bip_39` vs `bip39` | Verify package names |
| **Compromised Maintainer** | Upstream account takeover | Review before updating |
| **Build Pipeline Attack** | CI/CD compromise | Signed releases only |

**Action:** Review all dependency updates manually before merging

---

## PART 3: TESTING CADENCE

### Weekly Tasks

| Task | Owner | Time |
|------|-------|------|
| Review CVE feeds for dependencies | @black-team | 30 min |
| Check GitHub security advisories | @black-team | 15 min |
| Monitor Bitcoin/Lightning mailing lists | @mr-blackkeys | 30 min |
| Review Breez SDK commits for security fixes | @black-team | 30 min |

### Monthly Tasks

| Task | Owner | Time |
|------|-------|------|
| Run MobSF static analysis on latest build | @black-team | 2 hours |
| Update dependency vulnerability scan | @black-team | 1 hour |
| Review new academic papers (search terms above) | @mr-blackkeys | 2 hours |
| Test certificate pinning still working | @black-team | 1 hour |
| Verify secure storage on test devices | @black-team | 1 hour |

### Quarterly Tasks

| Task | Owner | Time |
|------|-------|------|
| Full red team engagement (internal) | Full team | 2 days |
| Memory forensics testing | @mr-blackkeys | 4 hours |
| Biometric bypass testing | @black-team | 4 hours |
| Protocol fuzzing (BOLT11/12) | @black-team | 1 day |
| Supply chain audit | @black-team | 4 hours |
| Update threat model | @mr-blackkeys | 2 hours |

### Annual Tasks

| Task | Owner | Time |
|------|-------|------|
| External penetration test | External firm | 1-2 weeks |
| Cryptographic audit | External auditor | 1 week |
| Review and update this playbook | Full team | 4 hours |
| Conference attendance (FC, IEEE S&P) | Rotating | 3-5 days |

---

## PART 4: TOOLS & TECHNIQUES

### Static Analysis

```bash
# MobSF (Mobile Security Framework)
docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf

# Upload APK/IPA for automated analysis
# Focus on:
# - Hardcoded secrets
# - Insecure storage
# - Missing certificate pinning
# - Improper input validation
```

### Dynamic Analysis

```bash
# Frida - Dynamic instrumentation
pip install frida-tools

# Hook SecureString to verify memory wiping
frida -U -f com.bolt21.bolt21 -l hooks/secure_string_test.js

# Bypass certificate pinning (testing only)
frida -U -f com.bolt21.bolt21 -l hooks/ssl_pinning_bypass.js
```

### Memory Forensics

```bash
# Android memory dump
adb shell
su
cat /proc/<pid>/maps > /sdcard/maps.txt
dd if=/proc/<pid>/mem of=/sdcard/mem.dump bs=1 skip=<heap_start> count=<heap_size>

# Search for mnemonic patterns
strings mem.dump | grep -E '\b([a-z]+\s+){11}[a-z]+\b'

# Expected: No matches (SecureString should wipe)
```

### Protocol Fuzzing

```bash
# Generate malformed BOLT11 invoices
# Test edge cases:
# - Maximum amount (overflow)
# - Invalid checksum
# - Unicode in description
# - Oversized payloads

# Use custom fuzzer or adapt: https://github.com/lightningnetwork/lnd/tree/master/fuzz
```

### Network Testing

```bash
# mitmproxy with custom CA
mitmproxy --mode regular -p 8080

# Expected: Connection rejected (pinning active)
# If connection succeeds: VULNERABILITY

# Burp Suite for API testing
# Focus on:
# - Community Node API
# - LND REST API (if configured)
# - Price oracle responses
```

---

## PART 5: INCIDENT RESPONSE

### If Vulnerability Discovered

**Severity Classification:**

| Level | Description | Response Time |
|-------|-------------|---------------|
| P0 (Critical) | Remote fund theft, key extraction | 24 hours |
| P1 (High) | Local fund theft with access, data leak | 48 hours |
| P2 (Medium) | Limited impact, requires conditions | 1 week |
| P3 (Low) | Theoretical, defense-in-depth | Next release |

**Response Process:**

1. **Assess** - Determine severity and blast radius
2. **Contain** - If active exploitation, consider emergency release
3. **Fix** - Develop and test patch
4. **Verify** - Red team verification of fix
5. **Deploy** - Release update (force update for P0)
6. **Document** - Add to security docs for future reference

### Emergency Contacts

```
Internal:
- @mr-blackkeys: Crypto/key management issues
- @black-team: Network/mobile/payment issues
- [Project Lead]: Release decisions

External:
- Breez SDK: security@breez.technology
- Flutter: security@flutter.dev
```

---

## PART 6: KNOWLEDGE BASE

### Past Vulnerabilities Fixed (Reference)

| ID | Issue | Fix | Lesson |
|----|-------|-----|--------|
| P0-01 | Community node MITM | HTTPS enforcement | Always validate schemes |
| P0-02 | SSRF via URL injection | Private network blocking | Blocklist RFC1918 ranges |
| P0-05 | LND integer overflow | BigInt with clamping | Never trust external ints |
| P0-06 | JSON parsing crashes | Type checking + try/catch | Validate all responses |
| P0-MEM | Mnemonic memory leak | SecureString triple-wipe | Avoid immutable strings for secrets |

### Common Attack Patterns

**Pattern 1: Integer Overflow**
```dart
// WRONG
final amount = int.parse(response['amount']);

// RIGHT
final amount = _safeParseInt(response['amount'], maxValue: 2100000000000000);
```

**Pattern 2: URL Injection**
```dart
// WRONG
final url = Uri.parse(userInput);

// RIGHT
if (uri.scheme != 'https') throw ArgumentError('HTTPS required');
if (_isPrivateNetwork(uri.host)) throw ArgumentError('Private network blocked');
```

**Pattern 3: Memory Safety**
```dart
// WRONG
final mnemonic = await storage.read('mnemonic');
// String stays in memory forever

// RIGHT
final secure = SecureString.fromString(mnemonic);
try {
  // use secure.value
} finally {
  secure.dispose();  // Triple-wipe memory
}
```

---

## APPENDIX: USEFUL COMMANDS

### Dependency Audit
```bash
# Check for outdated packages
flutter pub outdated

# Check for vulnerabilities (if available)
flutter pub deps

# Review specific package
flutter pub deps --style=compact | grep bip39
```

### Build Verification
```bash
# Verify APK signature
apksigner verify --print-certs bolt21.apk

# Check for debug flags
unzip -p bolt21.apk classes.dex | strings | grep -i debug
```

### Certificate Pin Verification
```bash
# Extract pins from network_security_config.xml
cat android/app/src/main/res/xml/network_security_config.xml | grep -A1 "pin-set"

# Verify live certificate matches
openssl s_client -connect community.bolt21.io:443 -servername community.bolt21.io 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
```

---

**Document Version:** 1.0
**Created:** 2025-12-31
**Next Review:** 2026-01-31

---

*"Stay paranoid, stay secure."* - Bolt21 Security Team
