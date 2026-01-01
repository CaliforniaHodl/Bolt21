import Foundation
import Security

/// SSL Certificate Pinning for iOS
/// SECURITY: Prevents MITM attacks by validating server certificates against known pins
///
/// This implementation pins certificates for critical endpoints:
/// - GitHub (for app updates)
/// - CoinGecko (for price data)
///
/// Note: Breez SDK handles its own certificate pinning internally
class CertificatePinner: NSObject, URLSessionDelegate {

    static let shared = CertificatePinner()

    /// SHA-256 certificate pins for trusted endpoints
    /// These are the SPKI (Subject Public Key Info) hashes
    private let pinnedHosts: [String: Set<String>] = [
        // GitHub - used for app update checks
        // Multiple pins for backup (primary + backup CA)
        "api.github.com": [
            // DigiCert Global Root G2
            "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=",
            // DigiCert Global Root CA
            "r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=",
        ],
        "raw.githubusercontent.com": [
            // DigiCert Global Root G2
            "i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=",
            // DigiCert Global Root CA
            "r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=",
        ],
        // CoinGecko - used for BTC price
        // Note: Price manipulation is mitigated in PriceService with sanity checks
        "api.coingecko.com": [
            // Cloudflare pins (CoinGecko uses Cloudflare)
            "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=",
            // Let's Encrypt backup
            "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=",
        ],
    ]

    /// Create a URLSession with certificate pinning enabled
    func createPinnedSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    /// URLSession delegate method for server trust evaluation
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check if we have pins for this host
        guard let expectedPins = pinnedHosts[host] else {
            // No pins for this host - use default validation
            // This allows other requests to proceed normally
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate the certificate chain
        var secResult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secResult)

        guard status == errSecSuccess,
              secResult == .unspecified || secResult == .proceed else {
            // Certificate chain validation failed
            NSLog("[CertPinner] Certificate chain validation failed for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract and verify the public key hash
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let serverPublicKey = SecCertificateCopyKey(serverCertificate),
              let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Calculate SHA-256 hash of the public key
        let hash = sha256(data: serverPublicKeyData)
        let hashBase64 = hash.base64EncodedString()

        // Check if the hash matches any of our pins
        if expectedPins.contains(hashBase64) {
            // Pin matched - allow connection
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Pin mismatch - possible MITM attack
            NSLog("[CertPinner] SECURITY: Certificate pin mismatch for \(host)")
            NSLog("[CertPinner] Expected one of: \(expectedPins)")
            NSLog("[CertPinner] Got: \(hashBase64)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// Calculate SHA-256 hash of data
    private func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

// MARK: - CommonCrypto Bridge
// Import CommonCrypto for SHA-256
import CommonCrypto
