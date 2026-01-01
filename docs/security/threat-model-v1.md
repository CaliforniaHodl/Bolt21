# Bolt21 Threat Model v1.0
**Document Owner:** @mr-blackkeys, @black-team
**Last Updated:** 2025-12-31
**Review Cadence:** Quarterly

---

## ASSET INVENTORY

### Critical Assets (Tier 1 - Loss = Fund Theft)

| Asset | Location | Current Defense | Risk Level |
|-------|----------|-----------------|------------|
| BIP39 Mnemonic | Secure Storage | AES-256-GCM + SecureString | LOW |
| HD Private Keys | Breez SDK | SDK-managed | LOW |
| LND Macaroon | Secure Storage | User-managed | MEDIUM |

### Sensitive Assets (Tier 2 - Loss = Privacy Breach)

| Asset | Location | Current Defense | Risk Level |
|-------|----------|-----------------|------------|
| Payment History | Breez SDK | Device-local | LOW |
| Wallet Balances | Breez SDK | Device-local | LOW |
| Transaction Metadata | Operation State | AES-256-GCM encrypted | LOW |
| LND Node URL | Secure Storage | Encrypted | LOW |

### Operational Assets (Tier 3 - Loss = Service Disruption)

| Asset | Location | Current Defense | Risk Level |
|-------|----------|-----------------|------------|
| App Configuration | SharedPreferences | Non-sensitive | LOW |
| Biometric Settings | Secure Storage | Encrypted | LOW |
| Price Cache | Memory | Non-persistent | LOW |

---

## THREAT ACTORS

### Actor 1: Opportunistic Thief
**Motivation:** Financial gain
**Capability:** Physical device access, basic technical skills
**Target:** Unlocked device, clipboard monitoring

| Attack Vector | Likelihood | Impact | Current Defense | Residual Risk |
|--------------|------------|--------|-----------------|---------------|
| Shoulder surfing mnemonic | MEDIUM | CRITICAL | Mnemonic hidden by default | LOW |
| Clipboard theft | MEDIUM | CRITICAL | 30s auto-clear | LOW |
| Unlocked device payment | HIGH | HIGH | Biometric for large payments | LOW |

### Actor 2: Sophisticated Attacker
**Motivation:** Financial gain, targeted attack
**Capability:** Malware, device compromise, social engineering
**Target:** High-value wallets, mnemonic extraction

| Attack Vector | Likelihood | Impact | Current Defense | Residual Risk |
|--------------|------------|--------|-----------------|---------------|
| Malware keylogger | LOW | CRITICAL | OS-level protection | MEDIUM |
| Memory forensics | LOW | CRITICAL | SecureString triple-wipe | LOW |
| Fake app (phishing) | MEDIUM | CRITICAL | App store verification | LOW |
| Social engineering | MEDIUM | CRITICAL | User education | MEDIUM |

### Actor 3: Network Attacker
**Motivation:** Financial gain, mass exploitation
**Capability:** MITM, DNS hijacking, rogue infrastructure
**Target:** API endpoints, payment routing

| Attack Vector | Likelihood | Impact | Current Defense | Residual Risk |
|--------------|------------|--------|-----------------|---------------|
| MITM on Community Node | MEDIUM | HIGH | Certificate pinning | LOW |
| Rogue LN routing node | LOW | MEDIUM | Breez SDK pathfinding | LOW |
| Price oracle manipulation | MEDIUM | LOW | 50% change limit | LOW |
| DNS hijacking | LOW | HIGH | Certificate pinning | LOW |

### Actor 4: Supply Chain Attacker
**Motivation:** Mass exploitation
**Capability:** Package compromise, maintainer takeover
**Target:** Dependencies, SDK, build pipeline

| Attack Vector | Likelihood | Impact | Current Defense | Residual Risk |
|--------------|------------|--------|-----------------|---------------|
| Breez SDK compromise | LOW | CRITICAL | Git commit pinning | LOW |
| Flutter package poison | LOW | HIGH | Package vetting | MEDIUM |
| Build pipeline injection | LOW | CRITICAL | Signed releases | LOW |

### Actor 5: State Actor
**Motivation:** Surveillance, asset seizure
**Capability:** Legal compulsion, advanced technical
**Target:** Backup extraction, device forensics

| Attack Vector | Likelihood | Impact | Current Defense | Residual Risk |
|--------------|------------|--------|-----------------|---------------|
| iCloud backup extraction | MEDIUM | CRITICAL | synchronizable: false | LOW |
| Device seizure + forensics | LOW | CRITICAL | SecureString wipe | LOW |
| Legal compulsion to Breez | LOW | MEDIUM | Non-custodial design | LOW |

---

## ATTACK TREES

### Tree 1: Mnemonic Extraction

```
Goal: Extract BIP39 mnemonic

├── Physical Access Attack
│   ├── [BLOCKED] View on screen → Hidden by default
│   ├── [BLOCKED] Clipboard theft → 30s auto-clear
│   ├── [BLOCKED] Screenshot capture → FLAG_SECURE
│   └── [MEDIUM] Social engineering → User education needed
│
├── Memory Attack
│   ├── [BLOCKED] Heap dump → SecureString triple-wipe
│   ├── [BLOCKED] Cold boot → RAM cleared on lock
│   └── [LOW] Crash dump during restore → P2-CRYPTO-01 (2-5s window)
│
├── Storage Attack
│   ├── [BLOCKED] Backup extraction → No iCloud sync
│   ├── [BLOCKED] Keychain dump → Device unlock required
│   └── [BLOCKED] SharedPrefs read → Not stored there
│
└── Network Attack
    ├── [BLOCKED] MITM backup sync → No cloud sync
    └── [N/A] Server-side extraction → Non-custodial
```

### Tree 2: Unauthorized Payment

```
Goal: Send payment without authorization

├── Bypass Biometric
│   ├── [BLOCKED] Single large payment → Biometric required
│   ├── [MEDIUM] Split payments (5min window) → Daily limit added
│   └── [BLOCKED] Fake biometric → OS-level protection
│
├── Bypass Rate Limiting
│   ├── [BLOCKED] Rapid payments → 5/minute limit
│   └── [BLOCKED] Modify app code → Signature verification
│
├── Invoice Manipulation
│   ├── [BLOCKED] Modify amount → Cryptographic signature
│   ├── [BLOCKED] Modify destination → Signature verification
│   └── [BLOCKED] Replay attack → One-time invoices
│
└── Network Interception
    ├── [BLOCKED] MITM payment → Certificate pinning
    └── [BLOCKED] Rogue routing → SDK pathfinding
```

### Tree 3: Supply Chain Compromise

```
Goal: Inject malicious code into app

├── Dependency Attack
│   ├── [LOW] Breez SDK compromise → Pinned to commit
│   ├── [MEDIUM] Flutter package → Manual review on update
│   └── [BLOCKED] Typosquatting → Package name verification
│
├── Build Attack
│   ├── [BLOCKED] CI/CD injection → Signed releases
│   ├── [BLOCKED] Developer machine → Code review
│   └── [BLOCKED] APK tampering → Play Protect
│
└── Update Attack
    ├── [BLOCKED] Fake update → GitHub PKI verification
    └── [BLOCKED] MITM update server → Certificate pinning
```

---

## RISK MATRIX

| Threat | Likelihood | Impact | Risk Score | Status |
|--------|------------|--------|------------|--------|
| Mnemonic memory leak | LOW | CRITICAL | MEDIUM | P2-CRYPTO-01 (accepted) |
| Biometric split-payment bypass | LOW | HIGH | MEDIUM | Daily limit mitigates |
| State file corruption | MEDIUM | LOW | LOW | SDK has canonical state |
| User LND misconfiguration | MEDIUM | HIGH | MEDIUM | User responsibility |
| Social engineering | MEDIUM | CRITICAL | HIGH | User education needed |
| Malware on device | LOW | CRITICAL | MEDIUM | OS-level protection |
| Supply chain compromise | LOW | CRITICAL | MEDIUM | Commit pinning |

---

## SECURITY CONTROLS SUMMARY

### Preventive Controls

| Control | Threats Mitigated |
|---------|-------------------|
| SecureString triple-wipe | Memory forensics, cold boot |
| Certificate pinning | MITM, DNS hijacking |
| HTTPS enforcement | Cleartext interception |
| SSRF blocklist | Internal network scanning |
| Unicode validation | Homograph/RTL attacks |
| Biometric auth | Unauthorized payments |
| Rate limiting | Payment flooding |

### Detective Controls

| Control | Threats Detected |
|---------|------------------|
| SecureLogger | Anomalous patterns |
| Price sanity check | Oracle manipulation |
| JSON type validation | Malformed responses |
| Operation state tracking | Incomplete operations |

### Corrective Controls

| Control | Recovery Action |
|---------|-----------------|
| Operation state recovery | Resume incomplete ops |
| Swap refund recovery | Reclaim stuck funds |
| Force update mechanism | Deploy critical patches |

---

## EMERGING THREATS TO MONITOR

### Near-Term (6 months)

| Threat | Relevance | Monitoring Action |
|--------|-----------|-------------------|
| Flutter VM memory bugs | Memory safety | Flutter security advisories |
| New LN attack vectors | Payment security | Lightning-dev mailing list |
| Mobile side-channel | Key extraction | Academic papers (FC, CCS) |

### Medium-Term (1-2 years)

| Threat | Relevance | Monitoring Action |
|--------|-----------|-------------------|
| Post-quantum crypto | Key derivation | NIST PQC standardization |
| Advanced TEE attacks | Keystore extraction | Hardware vendor bulletins |
| AI-powered phishing | Social engineering | Industry threat reports |

### Long-Term (3+ years)

| Threat | Relevance | Monitoring Action |
|--------|-----------|-------------------|
| Quantum computing | All crypto | Academic research |
| Mobile OS zero-days | Full compromise | Major vendor bulletins |
| Regulatory requirements | Compliance | Policy monitoring |

---

## REVIEW SCHEDULE

| Review Type | Frequency | Owner |
|-------------|-----------|-------|
| Threat model update | Quarterly | @mr-blackkeys |
| Risk assessment | Quarterly | @black-team |
| Control effectiveness | Monthly | @black-team |
| Emerging threat scan | Weekly | Rotating |

---

**Document Version:** 1.0
**Classification:** Internal - Security Team
**Next Review:** 2026-03-31
